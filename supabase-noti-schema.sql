-- Noti cloud sync schema
-- Cole este arquivo no Supabase em SQL Editor > New query > Run.
-- Nao use service_role key no site. A anon key publica funciona com estas regras RLS.

create table if not exists public.noti_user_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  profile jsonb not null default '{}'::jsonb,
  app_state jsonb not null default '{"folders":[],"notes":[]}'::jsonb,
  preferences jsonb not null default '{}'::jsonb,
  version integer not null default 1,
  updated_at timestamptz not null default now()
);

alter table public.noti_user_data
  add column if not exists user_id uuid,
  add column if not exists email text,
  add column if not exists profile jsonb not null default '{}'::jsonb,
  add column if not exists app_state jsonb not null default '{"folders":[],"notes":[]}'::jsonb,
  add column if not exists preferences jsonb not null default '{}'::jsonb,
  add column if not exists version integer not null default 1,
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.noti_user_data'::regclass
      and contype = 'p'
  ) then
    alter table public.noti_user_data
      alter column user_id set not null,
      add constraint noti_user_data_pkey primary key (user_id);
  end if;
end $$;

alter table public.noti_user_data enable row level security;

drop policy if exists "noti read own data" on public.noti_user_data;
drop policy if exists "noti insert own data" on public.noti_user_data;
drop policy if exists "noti update own data" on public.noti_user_data;
drop policy if exists "noti delete own data" on public.noti_user_data;

create policy "noti read own data"
on public.noti_user_data
for select
to authenticated
using (auth.uid() = user_id);

create policy "noti insert own data"
on public.noti_user_data
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "noti update own data"
on public.noti_user_data
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "noti delete own data"
on public.noti_user_data
for delete
to authenticated
using (auth.uid() = user_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.noti_user_data to authenticated;
