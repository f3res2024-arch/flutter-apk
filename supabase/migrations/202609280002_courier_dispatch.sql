-- Nova Delivery courier dispatch
alter table public.orders
  add column if not exists pickup_branch_id uuid references public.branches(id) on delete set null,
  add column if not exists customer_name text,
  add column if not exists restaurant_name text,
  add column if not exists pickup_address text,
  add column if not exists pickup_lat double precision,
  add column if not exists pickup_lng double precision,
  add column if not exists delivery_address text,
  add column if not exists accepted_at timestamptz;

create index if not exists orders_dispatch_idx on public.orders (status, courier_id, created_at desc);
create index if not exists orders_pickup_branch_idx on public.orders (pickup_branch_id);

create table if not exists public.order_rejections (
  order_id uuid not null references public.orders(id) on delete cascade,
  courier_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (order_id, courier_id)
);
alter table public.order_rejections enable row level security;
grant select, insert on public.order_rejections to authenticated;

drop policy if exists "couriers can read own rejections" on public.order_rejections;
create policy "couriers can read own rejections" on public.order_rejections
for select to authenticated using (courier_id = auth.uid());

drop policy if exists "couriers can reject orders" on public.order_rejections;
create policy "couriers can reject orders" on public.order_rejections
for insert to authenticated
with check (
  courier_id = auth.uid()
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'courier'::public.user_role and p.is_active = true
  )
);

grant select on public.orders to authenticated;
drop policy if exists "couriers can see unassigned pending orders" on public.orders;
create policy "couriers can see unassigned pending orders" on public.orders
for select to authenticated
using (
  courier_id = auth.uid()
  or (
    status = 'pending' and courier_id is null
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'courier'::public.user_role and p.is_active = true
    )
  )
);

create or replace function public.claim_order(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  claimed public.orders;
  uid uuid := auth.uid();
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists (
    select 1 from public.profiles p
    where p.id = uid and p.role = 'courier'::public.user_role and p.is_active = true
  ) then raise exception 'COURIER_ONLY'; end if;

  update public.orders
  set courier_id = uid, status = 'accepted', accepted_at = now(), updated_at = now()
  where id = p_order_id and status = 'pending' and courier_id is null
  returning * into claimed;

  if claimed.id is null then raise exception 'ORDER_ALREADY_CLAIMED'; end if;
  return claimed;
end;
$$;

revoke execute on function public.claim_order(uuid) from public, anon;
grant execute on function public.claim_order(uuid) to authenticated;

create or replace function public.reject_order(p_order_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists (
    select 1 from public.profiles p
    where p.id = uid and p.role = 'courier'::public.user_role and p.is_active = true
  ) then raise exception 'COURIER_ONLY'; end if;

  insert into public.order_rejections(order_id, courier_id)
  select p_order_id, uid
  where exists (
    select 1 from public.orders o
    where o.id = p_order_id and o.status = 'pending' and o.courier_id is null
  )
  on conflict (order_id, courier_id) do nothing;
  return true;
end;
$$;

revoke execute on function public.reject_order(uuid) from public, anon;
grant execute on function public.reject_order(uuid) to authenticated;
alter table public.orders replica identity full;
