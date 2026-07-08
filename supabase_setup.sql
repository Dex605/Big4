-- Run this in Supabase: Project → SQL Editor → New query → paste this → Run

create table if not exists app_state (
  id int primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

insert into app_state (id, data)
values (1, '{}'::jsonb)
on conflict (id) do nothing;

-- Enable realtime updates so all four devices sync live
alter publication supabase_realtime add table app_state;
