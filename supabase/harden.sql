-- ============================================================
--  XAVFSIZLIKNI QATTIQLASHTIRISH
--
--  Muammo: dastlabki qoidalar "tizimga kirgan har qanday foydalanuvchi"
--  ga to'liq huquq berardi. Supabase'da ochiq ro'yxatdan o'tish yoqiq
--  bo'lsa, istalgan odam o'zi hisob ochib, shu huquqni olib qo'yishi
--  mumkin edi.
--
--  Yechim: faqat ruxsat berilgan foydalanuvchilar ro'yxati.
--
--  Supabase Dashboard -> SQL Editor -> to'liq nusxalab Run bosing.
--  ESLATMA: avval Authentication -> Sign In / Providers -> Email
--  bo'limida "Allow new users to sign up" ni O'CHIRING.
-- ============================================================

-- 1) Ruxsat berilganlar ro'yxati
create table if not exists public.allowed_users (
  id       uuid primary key references auth.users (id) on delete cascade,
  note     text        not null default '',
  added_at timestamptz not null default now()
);

-- Bu jadvalga hech kim tashqaridan kira olmaydi:
-- RLS yoqilgan, lekin birorta ham policy yo'q.
alter table public.allowed_users enable row level security;

-- 2) Hozir mavjud foydalanuvchilarni ro'yxatga qo'shamiz.
--    (Bu qadam qoidalardan OLDIN bajarilishi shart, aks holda
--     o'zingiz ham kira olmay qolasiz.)
insert into public.allowed_users (id, note)
select id, coalesce(email, 'kassa')
from auth.users
on conflict (id) do nothing;

-- 3) Tekshiruv funksiyasi
create or replace function public.is_allowed()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from allowed_users where id = auth.uid()
  );
$$;

revoke all on function public.is_allowed() from public, anon;
grant execute on function public.is_allowed() to authenticated;

-- 4) Qoidalarni almashtiramiz: "har qanday kirgan" -> "ruxsat berilgan"
drop policy if exists "kassa_state_auth_all" on public.kassa_state;
drop policy if exists "kassa_state_allowed"  on public.kassa_state;
create policy "kassa_state_allowed" on public.kassa_state
  for all to authenticated
  using (public.is_allowed())
  with check (public.is_allowed());

drop policy if exists "receipts_auth_all" on public.receipts;
drop policy if exists "receipts_allowed"  on public.receipts;
create policy "receipts_allowed" on public.receipts
  for all to authenticated
  using (public.is_allowed())
  with check (public.is_allowed());

-- 5) Natijani tekshirish
select tablename, rowsecurity as rls_yoqilgan
from pg_tables where schemaname = 'public' order by tablename;

select tablename, policyname, roles, cmd
from pg_policies where schemaname = 'public' order by tablename;

select count(*) as ruxsat_berilganlar from public.allowed_users;

-- ============================================================
--  Keyinchalik yangi qurilma/hisob qo'shmoqchi bo'lsangiz:
--    1) Authentication -> Users -> Add user (parol bilan)
--    2) Shu yerga qo'shing:
--       insert into public.allowed_users (id, note)
--       select id, email from auth.users where email = 'yangi@email.uz';
-- ============================================================
