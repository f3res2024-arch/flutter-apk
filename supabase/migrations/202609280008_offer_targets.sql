-- Nova offer click destinations
alter table public.offers add column if not exists target_type text not null default 'coupon';
alter table public.offers add column if not exists target_value text;
alter table public.offers add column if not exists target_label text;
create index if not exists offers_active_sort_idx on public.offers(is_active, sort_order, created_at desc);
