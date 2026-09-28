-- Nova Delivery / Supabase initial schema
-- Run this migration in the Supabase SQL Editor.

create extension if not exists pgcrypto;

do $$ begin
  create type public.user_role as enum ('customer','courier','restaurant','admin');
exception when duplicate_object then null; end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  avatar_url text,
  role public.user_role not null default 'customer',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.restaurants (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete set null,
  name text not null,
  description text,
  phone text,
  logo_url text,
  cover_url text,
  rating numeric(2,1) not null default 0 check (rating between 0 and 5),
  delivery_fee numeric(10,2) not null default 0,
  min_order numeric(10,2) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  address text not null,
  lat double precision,
  lng double precision,
  phone text,
  opening_time time,
  closing_time time,
  is_open boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.menu_categories (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  sort_order int not null default 0,
  is_active boolean not null default true
);

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  category_id uuid references public.menu_categories(id) on delete set null,
  name text not null,
  description text,
  image_url text,
  price numeric(10,2) not null check (price >= 0),
  sort_order int not null default 0,
  is_available boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  label text not null default 'المنزل',
  address text not null,
  lat double precision,
  lng double precision,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id) on delete restrict,
  restaurant_id uuid not null references public.restaurants(id) on delete restrict,
  courier_id uuid references public.profiles(id) on delete set null,
  address_id uuid references public.addresses(id) on delete set null,
  status text not null default 'pending'
    check (status in ('pending','accepted','preparing','ready','picked_up','on_the_way','delivered','cancelled')),
  subtotal numeric(10,2) not null default 0,
  delivery_fee numeric(10,2) not null default 0,
  discount numeric(10,2) not null default 0,
  total numeric(10,2) not null default 0,
  payment_method text not null default 'cash'
    check (payment_method in ('cash','card','wallet')),
  notes text,
  customer_lat double precision,
  customer_lng double precision,
  courier_lat double precision,
  courier_lng double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  menu_item_id uuid references public.menu_items(id) on delete set null,
  item_name text not null,
  unit_price numeric(10,2) not null,
  quantity int not null check (quantity > 0),
  options jsonb not null default '{}'::jsonb
);

create table if not exists public.favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, restaurant_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null default 'general',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists restaurants_active_idx on public.restaurants(is_active);
create index if not exists menu_items_restaurant_idx on public.menu_items(restaurant_id, is_available);
create index if not exists orders_customer_idx on public.orders(customer_id, created_at desc);
create index if not exists orders_courier_idx on public.orders(courier_id, status);
create index if not exists notifications_user_idx on public.notifications(user_id, created_at desc);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', new.email), new.phone)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.restaurants enable row level security;
alter table public.branches enable row level security;
alter table public.menu_categories enable row level security;
alter table public.menu_items enable row level security;
alter table public.addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.favorites enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "profiles own read" on public.profiles;
create policy "profiles own read" on public.profiles for select using (auth.uid() = id);

drop policy if exists "profiles own update" on public.profiles;
create policy "profiles own update" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "restaurants public read" on public.restaurants;
create policy "restaurants public read" on public.restaurants for select using (is_active = true);

drop policy if exists "branches public read" on public.branches;
create policy "branches public read" on public.branches for select using (
  exists (select 1 from public.restaurants r where r.id = restaurant_id and r.is_active = true)
);

drop policy if exists "menu categories public read" on public.menu_categories;
create policy "menu categories public read" on public.menu_categories for select using (
  is_active = true and exists (select 1 from public.restaurants r where r.id = restaurant_id and r.is_active = true)
);

drop policy if exists "menu items public read" on public.menu_items;
create policy "menu items public read" on public.menu_items for select using (
  is_available = true and exists (select 1 from public.restaurants r where r.id = restaurant_id and r.is_active = true)
);

drop policy if exists "addresses own all" on public.addresses;
create policy "addresses own all" on public.addresses for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "orders customer read" on public.orders;
create policy "orders customer read" on public.orders for select using (auth.uid() = customer_id or auth.uid() = courier_id);

drop policy if exists "orders customer create" on public.orders;
create policy "orders customer create" on public.orders for insert with check (auth.uid() = customer_id);

drop policy if exists "orders customer update" on public.orders;
create policy "orders customer update" on public.orders for update using (auth.uid() = customer_id or auth.uid() = courier_id);

drop policy if exists "order items participant read" on public.order_items;
create policy "order items participant read" on public.order_items for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.customer_id = auth.uid() or o.courier_id = auth.uid()))
);

drop policy if exists "order items customer create" on public.order_items;
create policy "order items customer create" on public.order_items for insert with check (
  exists (select 1 from public.orders o where o.id = order_id and o.customer_id = auth.uid())
);

drop policy if exists "favorites own all" on public.favorites;
create policy "favorites own all" on public.favorites for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "notifications own read" on public.notifications;
create policy "notifications own read" on public.notifications for select using (auth.uid() = user_id);

drop policy if exists "notifications own update" on public.notifications;
create policy "notifications own update" on public.notifications for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Realtime order tracking.
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.notifications;

-- Storage bucket for avatars, restaurant/food images and delivery media.
insert into storage.buckets (id, name, public)
values ('nova-media', 'nova-media', true)
on conflict (id) do update set public = true;

drop policy if exists "nova media public read" on storage.objects;
create policy "nova media public read" on storage.objects for select using (bucket_id = 'nova-media');

drop policy if exists "nova media authenticated upload" on storage.objects;
create policy "nova media authenticated upload" on storage.objects
for insert to authenticated
with check (bucket_id = 'nova-media');

drop policy if exists "nova media owner update" on storage.objects;
create policy "nova media owner update" on storage.objects
for update to authenticated
using (bucket_id = 'nova-media' and owner_id = auth.uid())
with check (bucket_id = 'nova-media' and owner_id = auth.uid());

drop policy if exists "nova media owner delete" on storage.objects;
create policy "nova media owner delete" on storage.objects
for delete to authenticated
using (bucket_id = 'nova-media' and owner_id = auth.uid());
