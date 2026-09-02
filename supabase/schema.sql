-- ============================================================
--  Saxovat Kassa - Supabase sxemasi
--  Supabase Dashboard -> SQL Editor'ga to'liq nusxalab, Run bosing.
-- ============================================================

-- 1) Kassa holati: stollar, menyu, kategoriyalar, sozlamalar.
--    Bitta qator (id = 'main') - butun holat JSON ko'rinishida.
create table if not exists public.kassa_state (
  id          text primary key,
  data        jsonb       not null,
  updated_at  timestamptz not null default now()
);

-- 2) Yopilgan cheklar. Har bir chek - alohida qator.
--    Hisobotlarni to'g'ridan-to'g'ri SQL bilan olish mumkin.
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

create index if not exists receipts_closed_at_idx
  on public.receipts (closed_at desc);

-- 3) Xavfsizlik: faqat tizimga kirgan foydalanuvchi o'qiy va yoza oladi.
alter table public.kassa_state enable row level security;
alter table public.receipts    enable row level security;

drop policy if exists "kassa_state_auth_all" on public.kassa_state;
create policy "kassa_state_auth_all" on public.kassa_state
  for all to authenticated
  using (true) with check (true);

drop policy if exists "receipts_auth_all" on public.receipts;
create policy "receipts_auth_all" on public.receipts
  for all to authenticated
  using (true) with check (true);

-- ============================================================
--  Foydali so'rovlar (ixtiyoriy)
-- ============================================================

-- Kunlik tushum:
--   select date(closed_at at time zone 'Asia/Tashkent') as kun,
--          count(*) as cheklar,
--          sum(total) as tushum
--   from public.receipts
--   group by 1 order by 1 desc;

-- Eng ko'p sotilgan mahsulotlar:
--   select l->>'name' as mahsulot,
--          sum((l->>'qty')::int) as soni,
--          sum((l->>'qty')::int * (l->>'price')::bigint) as summa
--   from public.receipts, jsonb_array_elements(lines) as l
--   group by 1 order by soni desc limit 20;
