-- Nova owner studio and profile bootstrap
create table if not exists public.app_content (
  key text primary key,
  text_value text,
  image_url text,
  updated_at timestamptz not null default now()
);

alter table public.app_content enable row level security;
grant select on public.app_content to anon, authenticated;
grant insert, update, delete on public.app_content to authenticated;

drop policy if exists "app content public read" on public.app_content;
create policy "app content public read" on public.app_content for select to anon, authenticated using (true);

drop policy if exists "app content owner insert" on public.app_content;
create policy "app content owner insert" on public.app_content for insert to authenticated
with check (exists (select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));

drop policy if exists "app content owner update" on public.app_content;
create policy "app content owner update" on public.app_content for update to authenticated
using (exists (select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'))
with check (exists (select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));

drop policy if exists "app content owner delete" on public.app_content;
create policy "app content owner delete" on public.app_content for delete to authenticated
using (exists (select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));

insert into public.app_content(key,text_value) values
 ('home_greeting','أكلك الحقيقي… في طريقه ليك 👋'),
 ('mood_title','اختار إللي على مزاجك'),
 ('home_hero_title','كل اللي نفسك فيه…'),
 ('home_hero_subtitle','يوصل لبابك بسرعة 🚀')
on conflict (key) do nothing;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare assigned_role public.user_role := 'customer';
begin
  if lower(coalesce(new.email,''))='faresbuda112@gmail.com' then assigned_role:='admin'; end if;
  insert into public.profiles(id,full_name,role)
  values(new.id,coalesce(nullif(new.raw_user_meta_data->>'full_name',''),split_part(coalesce(new.email,''),'@',1)),assigned_role)
  on conflict(id) do update set full_name=excluded.full_name,updated_at=now();
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
