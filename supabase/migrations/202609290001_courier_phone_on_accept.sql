-- Store the courier phone on an accepted order so the customer can call the assigned courier.
alter table public.orders
  add column if not exists courier_phone text;

create or replace function public.claim_order(p_order_id uuid)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  claimed public.orders;
  uid uuid := auth.uid();
  courier_phone_value text;
begin
  if uid is null then raise exception 'AUTH_REQUIRED'; end if;

  select p.phone into courier_phone_value
  from public.profiles p
  where p.id = uid
    and p.role = 'courier'::public.user_role
    and p.is_active = true;

  if courier_phone_value is null then
    raise exception 'COURIER_PHONE_REQUIRED';
  end if;

  update public.orders
  set courier_id = uid,
      courier_phone = courier_phone_value,
      status = 'accepted',
      accepted_at = now(),
      updated_at = now()
  where id = p_order_id
    and status = 'pending'
    and courier_id is null
  returning * into claimed;

  if claimed.id is null then raise exception 'ORDER_ALREADY_CLAIMED'; end if;
  return claimed;
end;
$$;

revoke execute on function public.claim_order(uuid) from public, anon;
grant execute on function public.claim_order(uuid) to authenticated;
