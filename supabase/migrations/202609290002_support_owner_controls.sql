-- Nova support escalation controls: owner accept/reject/close with server-side authorization.

create or replace function public.claim_support_conversation(p_conversation_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, private
as $$
declare changed integer;
begin
  if not private.is_admin() then raise exception 'admin_only'; end if;
  update public.support_conversations
  set status='admin_active', assigned_admin_id=auth.uid(), updated_at=now()
  where id=p_conversation_id and status='waiting_admin' and assigned_admin_id is null;
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;
revoke all on function public.claim_support_conversation(uuid) from public;
grant execute on function public.claim_support_conversation(uuid) to authenticated;

create or replace function public.reject_support_conversation(p_conversation_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, private
as $$
declare changed integer;
begin
  if not private.is_admin() then raise exception 'admin_only'; end if;
  update public.support_conversations
  set status='ai', assigned_admin_id=null, updated_at=now()
  where id=p_conversation_id and status='waiting_admin';
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;
revoke all on function public.reject_support_conversation(uuid) from public;
grant execute on function public.reject_support_conversation(uuid) to authenticated;

create or replace function public.close_support_conversation(p_conversation_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, private
as $$
declare changed integer;
begin
  if not private.is_admin() then raise exception 'admin_only'; end if;
  update public.support_conversations
  set status='closed', updated_at=now()
  where id=p_conversation_id and status <> 'closed';
  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;
revoke all on function public.close_support_conversation(uuid) from public;
grant execute on function public.close_support_conversation(uuid) to authenticated;

drop policy if exists "support messages admin insert" on public.support_messages;
create policy "support messages admin insert"
on public.support_messages for insert to authenticated
with check (
  sender_type='admin'
  and sender_id=auth.uid()
  and private.is_admin()
  and exists(
    select 1 from public.support_conversations c
    where c.id=conversation_id
      and c.status='admin_active'
      and c.assigned_admin_id=auth.uid()
  )
);

drop policy if exists "support conversations admin update" on public.support_conversations;
create policy "support conversations admin update"
on public.support_conversations for update to authenticated
using (private.is_admin())
with check (private.is_admin());

-- Customer uploads are allowed only after an owner has accepted the conversation.
drop policy if exists "nova media support customer upload" on storage.objects;
create policy "nova media support customer upload"
on storage.objects for insert to authenticated
with check (
  bucket_id='nova-media'
  and (storage.foldername(name))[1]='support'
  and (storage.foldername(name))[3]=auth.uid()::text
  and exists(
    select 1 from public.support_conversations c
    where c.id=((storage.foldername(name))[2])::uuid
      and c.customer_id=auth.uid()
      and c.status='admin_active'
      and c.assigned_admin_id is not null
  )
);
