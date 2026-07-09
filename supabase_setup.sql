-- Run this in Supabase: Project → SQL Editor → New query → paste this → Run
-- Safe to run more than once — every step here can be re-run without errors.

create table if not exists app_state (
  id int primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

insert into app_state (id, data)
values (1, '{}'::jsonb)
on conflict (id) do nothing;

-- Enable realtime updates so all four devices sync live (safe to re-run)
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'app_state'
  ) then
    alter publication supabase_realtime add table app_state;
  end if;
end $$;

-- ===== Photo storage (separate from the app_state record above) =====
-- Photos used to be embedded directly inside app_state, which made that one shared
-- record grow too large to save once enough photos piled up — causing everything
-- (messages, posts, avatars) to silently fail to save. This moves photos into
-- proper file storage instead, so app_state stays small and saves keep working.

insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

drop policy if exists "Public read access on photos" on storage.objects;
create policy "Public read access on photos"
on storage.objects for select
using ( bucket_id = 'photos' );

drop policy if exists "Public upload access on photos" on storage.objects;
create policy "Public upload access on photos"
on storage.objects for insert
with check ( bucket_id = 'photos' );

drop policy if exists "Public update access on photos" on storage.objects;
create policy "Public update access on photos"
on storage.objects for update
using ( bucket_id = 'photos' );

drop policy if exists "Public delete access on photos" on storage.objects;
create policy "Public delete access on photos"
on storage.objects for delete
using ( bucket_id = 'photos' );
