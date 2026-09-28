-- Nova offer click destinations
alter table public.offers
  add column if not exists target_type text not null default 'coupon',
  add column if not exists target_value text,
  add column if not exists target_label text;

alter table public.offers drop constraint if exists offers_target_type_check;
alter table public.offers add constraint offers_target_type_check
  check (target_type in ('coupon','restaurant','category','map','home','none'));

create index if not exists offers_active_sort_idx
  on public.offers(is_active, sort_order, created_at desc);
