create schema if not exists private;

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to authenticated;

create table if not exists public.support_conversations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'ai',
  assigned_admin_id uuid references auth.users(id) on delete set null,
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint support_conversations_status_check check (status in ('ai','waiting_admin','admin_active','closed'))
);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.support_conversations(id) on delete cascade,
  sender_type text not null,
  sender_id uuid references auth.users(id) on delete set null,
  body text not null default '',
  image_url text,
  created_at timestamptz not null default now(),
  constraint support_messages_sender_check check (sender_type in ('customer','ai','admin')),
  constraint support_messages_content_check check (length(trim(body)) > 0 or image_url is not null)
);

create index if not exists support_conversations_customer_idx on public.support_conversations(customer_id, updated_at desc);
create index if not exists support_conversations_status_idx on public.support_conversations(status, last_message_at desc);
create index if not exists support_messages_conversation_idx on public.support_messages(conversation_id, created_at);

alter table public.support_conversations enable row level security;
alter table public.support_messages enable row level security;

drop policy if exists "support conversations customer read" on public.support_conversations;
create policy "support conversations customer read" on public.support_conversations for select to authenticated using (customer_id = auth.uid() or private.is_admin());

drop policy if exists "support conversations customer create" on public.support_conversations;
create policy "support conversations customer create" on public.support_conversations for insert to authenticated with check (customer_id = auth.uid());

drop policy if exists "support messages read" on public.support_messages;
create policy "support messages read" on public.support_messages for select to authenticated using (
  private.is_admin() or exists(select 1 from public.support_conversations c where c.id = conversation_id and c.customer_id = auth.uid())
);

drop policy if exists "support messages customer insert" on public.support_messages;
create policy "support messages customer insert" on public.support_messages for insert to authenticated with check (
  sender_type = 'customer' and sender_id = auth.uid() and exists(
    select 1 from public.support_conversations c where c.id = conversation_id and c.customer_id = auth.uid() and c.status <> 'closed'
  )
);

drop policy if exists "support messages admin insert" on public.support_messages;
create policy "support messages admin insert" on public.support_messages for insert to authenticated with check (
  sender_type = 'admin' and sender_id = auth.uid() and private.is_admin() and exists(select 1 from public.support_conversations c where c.id = conversation_id)
);

create or replace function public.touch_support_conversation()
returns trigger language plpgsql security invoker set search_path = public, private as $
begin
  update public.support_conversations
  set last_message_at = new.created_at, updated_at = now(),
      status = case when new.sender_type = 'admin' then 'admin_active'
                    when new.sender_type = 'customer' and status = 'admin_active' then 'admin_active'
                    else status end
  where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists support_message_touch on public.support_messages;
create trigger support_message_touch after insert on public.support_messages for each row execute function public.touch_support_conversation();

do $$
begin
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='support_conversations') then alter publication supabase_realtime add table public.support_conversations; end if;
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='support_messages') then alter publication supabase_realtime add table public.support_messages; end if;
end $$;

drop policy if exists "nova media support customer upload" on storage.objects;
create policy "nova media support customer upload" on storage.objects for insert to authenticated with check (
  bucket_id = 'nova-media'
  and (storage.foldername(name))[1] = 'support'
  and (storage.foldername(name))[3] = (auth.uid())::text
  and exists(
    select 1 from public.support_conversations c
    where c.id = ((storage.foldername(name))[2])::uuid
      and c.customer_id = auth.uid()
      and c.status = 'admin_active'
      and exists(select 1 from public.support_messages m where m.conversation_id = c.id and m.sender_type = 'admin')
  )
);
