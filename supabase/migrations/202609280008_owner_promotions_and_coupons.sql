-- Nova owner promotions, coupons and offers
create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  description text,
  discount_type text not null default 'percentage' check (discount_type in ('percentage','fixed','free_delivery')),
  discount_value numeric not null default 0 check (discount_value >= 0),
  min_order numeric not null default 0 check (min_order >= 0),
  max_discount numeric,
  usage_limit integer,
  usage_count integer not null default 0 check (usage_count >= 0),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.offers (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text,
  image_url text,
  coupon_id uuid references public.coupons(id) on delete set null,
  sort_order integer not null default 0,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.coupons enable row level security;
alter table public.offers enable row level security;
grant select on public.coupons, public.offers to anon, authenticated;
grant insert, update, delete on public.coupons, public.offers to authenticated;
drop policy if exists "coupons public active read" on public.coupons;
create policy "coupons public active read" on public.coupons for select to anon, authenticated using (is_active=true and (ends_at is null or ends_at>now()) and starts_at<=now());
drop policy if exists "coupons admin write" on public.coupons;
create policy "coupons admin write" on public.coupons for all to authenticated using (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin')) with check (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));
drop policy if exists "offers public active read" on public.offers;
create policy "offers public active read" on public.offers for select to anon, authenticated using (is_active=true and (ends_at is null or ends_at>now()) and starts_at<=now());
drop policy if exists "offers admin write" on public.offers;
create policy "offers admin write" on public.offers for all to authenticated using (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin')) with check (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));
create index if not exists coupons_active_idx on public.coupons(is_active,starts_at,ends_at);
create index if not exists offers_active_idx on public.offers(is_active,sort_order,starts_at,ends_at);
