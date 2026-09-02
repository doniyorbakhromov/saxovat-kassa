-- ============================================================
--  Saxovat Kassa - ko'p qurilmali sxema (v2)
--
--  Nega o'zgardi: ilgari butun holat bitta JSON yozuvda turardi va
--  har bir qurilma uni to'liq qayta yozardi - ikkinchi qurilmaning
--  zakazi jimgina yo'qolardi. Endi har bir stol, har bir buyurtma
--  qatori, har bir mahsulot alohida qator. Ikki qurilma turli
--  narsalarni o'zgartirsa, ular to'qnashmaydi.
--
--  Supabase Dashboard -> SQL Editor -> to'liq nusxalab Run bosing.
--  Skript qayta-qayta ishga tushirilsa ham xavfsiz.
-- ============================================================

-- ------------------------------------------------------------
-- 0) Ruxsat ro'yxati (harden.sql ishga tushirilmagan bo'lsa ham yaratiladi)
-- ------------------------------------------------------------
create table if not exists public.allowed_users (
  id       uuid primary key references auth.users (id) on delete cascade,
  note     text        not null default '',
  added_at timestamptz not null default now()
);
alter table public.allowed_users enable row level security;

insert into public.allowed_users (id, note)
select id, coalesce(email, 'kassa') from auth.users
on conflict (id) do nothing;

create or replace function public.is_allowed()
returns boolean
language sql security definer stable
set search_path = public
as $$ select exists (select 1 from allowed_users where id = auth.uid()); $$;

revoke all on function public.is_allowed() from public, anon;
grant execute on function public.is_allowed() to authenticated;

-- ------------------------------------------------------------
-- 1) Jadvallar
--    updated_by - o'zgartirgan qurilmaning belgisi. Qurilma o'z
--    o'zgarishining aks-sadosini qayta qo'llamasligi uchun kerak.
-- ------------------------------------------------------------
create table if not exists public.tables (
  id         text primary key,
  name       text        not null,
  zone       text        not null default 'Zal',
  seats      int         not null default 4,
  opened_at  timestamptz,                    -- null bo'lsa stol bo'sh
  position   int         not null default 0,
  updated_at timestamptz not null default now(),
  updated_by text        not null default ''
);

create table if not exists public.order_lines (
  id         text primary key,
  table_id   text        not null references public.tables (id) on delete cascade,
  item_id    text        not null default '',
  name       text        not null,
  price      bigint      not null default 0,
  qty        int         not null default 1,
  note       text        not null default '',
  added_at   timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by text        not null default ''
);
create index if not exists order_lines_table_idx on public.order_lines (table_id);

create table if not exists public.menu_items (
  id         text primary key,
  name       text        not null,
  price      bigint      not null default 0,
  category   text        not null default '',
  icon       text        not null default 'boshqa',
  active     boolean     not null default true,
  position   int         not null default 0,
  updated_at timestamptz not null default now(),
  updated_by text        not null default ''
);

create table if not exists public.categories (
  name       text primary key,
  position   int         not null default 0,
  updated_at timestamptz not null default now(),
  updated_by text        not null default ''
);

create table if not exists public.settings (
  id                text primary key,
  venue_name        text   not null default 'SAXOVAT BAR',
  service_percent   int    not null default 0,
  pin               text   not null default '',
  auto_lock_minutes int    not null default 10,
  updated_at        timestamptz not null default now(),
  updated_by        text   not null default ''
);

-- receipts allaqachon mavjud (schema.sql). Yo'q bo'lsa yaratamiz.
create table if not exists public.receipts (
  id          text primary key,
  table_id    text,
  table_name  text        not null,
  zone        text,
  opened_at   timestamptz not null,
  closed_at   timestamptz not null,
  lines       jsonb       not null,
  subtotal    bigint      not null default 0,
  discount    bigint      not null default 0,
  service     bigint      not null default 0,
  total       bigint      not null default 0,
  method      text        not null default 'Naqd',
  cash_given  bigint      not null default 0,
  note        text        not null default '',
  created_at  timestamptz not null default now()
);
create index if not exists receipts_closed_at_idx on public.receipts (closed_at desc);

-- ------------------------------------------------------------
-- 2) Eski yagona yozuvdan ko'chirish (agar bor bo'lsa)
-- ------------------------------------------------------------
do $$
begin
  if exists (select 1 from information_schema.tables
             where table_schema = 'public' and table_name = 'kassa_state') then

    insert into public.tables (id, name, zone, seats, opened_at)
    select t->>'id', coalesce(t->>'name','Stol'), coalesce(t->>'zone','Zal'),
           coalesce((t->>'seats')::int, 4), (t->>'openedAt')::timestamptz
    from public.kassa_state ks, jsonb_array_elements(ks.data->'tables') t
    where ks.id = 'main'
    on conflict (id) do nothing;

    insert into public.order_lines (id, table_id, item_id, name, price, qty, note, added_at)
    select l->>'id', t->>'id', coalesce(l->>'itemId',''), coalesce(l->>'name','?'),
           coalesce((l->>'price')::bigint, 0), coalesce((l->>'qty')::int, 1),
           coalesce(l->>'note',''),
           coalesce((l->>'addedAt')::timestamptz, now())
    from public.kassa_state ks,
         jsonb_array_elements(ks.data->'tables') t,
         jsonb_array_elements(t->'lines') l
    where ks.id = 'main'
    on conflict (id) do nothing;

    insert into public.menu_items (id, name, price, category, icon, active)
    select m->>'id', coalesce(m->>'name','?'), coalesce((m->>'price')::bigint, 0),
           coalesce(m->>'category',''), coalesce(m->>'icon','boshqa'),
           coalesce((m->>'active')::boolean, true)
    from public.kassa_state ks, jsonb_array_elements(ks.data->'menu') m
    where ks.id = 'main'
    on conflict (id) do nothing;

    insert into public.categories (name, position)
    select c.value #>> '{}', c.ordinality::int
    from public.kassa_state ks,
         jsonb_array_elements(ks.data->'categories') with ordinality c
    where ks.id = 'main'
    on conflict (name) do nothing;

    insert into public.settings (id, venue_name, service_percent, pin, auto_lock_minutes)
    select 'main',
           coalesce(ks.data->'settings'->>'venueName','SAXOVAT BAR'),
           coalesce((ks.data->'settings'->>'servicePercent')::int, 0),
           coalesce(ks.data->'settings'->>'pin',''),
           coalesce((ks.data->'settings'->>'autoLockMinutes')::int, 10)
    from public.kassa_state ks where ks.id = 'main'
    on conflict (id) do nothing;

  end if;
end $$;

-- ------------------------------------------------------------
-- 3) Xavfsizlik: faqat ruxsat ro'yxatidagilar
--    (har bir jadval uchun ochiq yozilgan - Supabase tekshiruvi
--     sikl ichini o'qiy olmaydi va bekorga ogohlantiradi)
-- ------------------------------------------------------------
alter table public.tables      enable row level security;
alter table public.order_lines enable row level security;
alter table public.menu_items  enable row level security;
alter table public.categories  enable row level security;
alter table public.settings    enable row level security;
alter table public.receipts    enable row level security;

drop policy if exists "tables_allowed" on public.tables;
create policy "tables_allowed" on public.tables
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

drop policy if exists "order_lines_allowed" on public.order_lines;
create policy "order_lines_allowed" on public.order_lines
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

drop policy if exists "menu_items_allowed" on public.menu_items;
create policy "menu_items_allowed" on public.menu_items
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

drop policy if exists "categories_allowed" on public.categories;
create policy "categories_allowed" on public.categories
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

drop policy if exists "settings_allowed" on public.settings;
create policy "settings_allowed" on public.settings
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

drop policy if exists "receipts_allowed" on public.receipts;
create policy "receipts_allowed" on public.receipts
  for all to authenticated
  using (public.is_allowed()) with check (public.is_allowed());

-- Eski keng qoidalarni olib tashlaymiz
drop policy if exists "kassa_state_auth_all" on public.kassa_state;
drop policy if exists "receipts_auth_all"    on public.receipts;

-- ------------------------------------------------------------
-- 4) Real vaqtda uzatish
-- ------------------------------------------------------------
-- O'chirish hodisasida ham to'liq qator kelishi uchun
alter table public.tables      replica identity full;
alter table public.order_lines replica identity full;
alter table public.menu_items  replica identity full;
alter table public.categories  replica identity full;
alter table public.settings    replica identity full;
alter table public.receipts    replica identity full;

-- Jadval nashrga allaqachon qo'shilgan bo'lsa xato bermasin
do $$
declare t text;
begin
  foreach t in array array['tables','order_lines','menu_items','categories','settings','receipts']
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ------------------------------------------------------------
-- 5) Tekshirish
-- ------------------------------------------------------------
select tablename, rowsecurity as rls from pg_tables
where schemaname = 'public' order by tablename;

select count(*) as ruxsat_berilganlar from public.allowed_users;

select tablename from pg_publication_tables
where pubname = 'supabase_realtime' and schemaname = 'public' order by 1;
