-- Nova owner editing and storage hardening
drop policy if exists "nova media authenticated upload" on storage.objects;
drop policy if exists "nova media owner update" on storage.objects;
drop policy if exists "nova media owner delete" on storage.objects;
create policy "nova media avatar upload" on storage.objects for insert to authenticated
with check (bucket_id='nova-media' and (storage.foldername(name))[1]='avatars' and (storage.foldername(name))[2]=(select auth.uid()::text));
create policy "nova media admin upload" on storage.objects for insert to authenticated
with check (bucket_id='nova-media' and (storage.foldername(name))[1] in ('restaurants','menu','content') and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));
create policy "nova media owner update" on storage.objects for update to authenticated
using (bucket_id='nova-media' and (owner_id=(select auth.uid()::text) or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin')))
with check (bucket_id='nova-media' and (owner_id=(select auth.uid()::text) or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin')));
create policy "nova media owner delete" on storage.objects for delete to authenticated
using (bucket_id='nova-media' and (owner_id=(select auth.uid()::text) or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin')));
drop policy if exists "restaurants owner update" on public.restaurants;
create policy "restaurants owner update" on public.restaurants for update to authenticated
using (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'))
with check (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));
drop policy if exists "menu items owner insert" on public.menu_items;
drop policy if exists "menu items owner update" on public.menu_items;
create policy "menu items owner insert" on public.menu_items for insert to authenticated
with check (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));
create policy "menu items owner update" on public.menu_items for update to authenticated
using (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'))
with check (exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin'));