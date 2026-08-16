-- Advisor Activity Dashboard — Supabase schema
-- Paste this whole file into Supabase: Project → SQL Editor → New query → Run

-- 1. Roster
create table if not exists advisors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  created_at timestamptz not null default now()
);

-- 2. One row per advisor per day
create table if not exists entries (
  id uuid primary key default gen_random_uuid(),
  advisor_code text not null references advisors(code) on delete cascade,
  entry_date date not null,
  prospecting int not null default 0,
  approaching int not null default 0,
  relationship int not null default 0,
  appts int not null default 0,
  presented int not null default 0,
  closed int not null default 0,
  social boolean not null default false,
  note text default '',
  updated_at timestamptz not null default now(),
  unique (advisor_code, entry_date)
);

-- 3. Daily targets, one row per stage
create table if not exists targets (
  stage text primary key,
  daily_target int not null default 0
);

insert into targets (stage, daily_target) values
  ('prospecting', 5), ('approaching', 5), ('relationship', 3),
  ('appts', 1), ('presented', 1), ('closed', 0)
on conflict (stage) do nothing;

-- 4. Small key/value table, currently just holds the manager PIN
create table if not exists settings (
  key text primary key,
  value text
);

-- 5. Atomic +1 / -1 tap. Doing the increment inside the database (rather than
--    read-modify-write from the browser) is what actually fixes the
--    lost-update race condition, unlike the client-side read/write approach.
create or replace function bump_metric(p_code text, p_date date, p_field text, p_delta int)
returns void as $$
begin
  if p_field not in ('prospecting','approaching','relationship','appts','presented','closed') then
    raise exception 'invalid field: %', p_field;
  end if;

  insert into entries (advisor_code, entry_date)
  values (p_code, p_date)
  on conflict (advisor_code, entry_date) do nothing;

  execute format(
    'update entries set %I = greatest(0, %I + $1), updated_at = now() where advisor_code = $2 and entry_date = $3',
    p_field, p_field
  ) using p_delta, p_code, p_date;
end;
$$ language plpgsql security definer;

-- 6. Row Level Security
-- This app has no real user accounts — it uses the same "advisor code as
-- login" model as before, checked in the app, not the database. That means
-- anyone with your public anon key (visible in the page source) could call
-- the Supabase API directly and bypass the app's checks. Fine for a low-
-- stakes internal tool; not fine for anything sensitive. A future upgrade
-- to real Supabase Auth would let these policies check auth.uid() instead
-- of allowing anon for everything.
alter table advisors enable row level security;
alter table entries enable row level security;
alter table targets enable row level security;
alter table settings enable row level security;

create policy "anon read advisors" on advisors for select using (true);
create policy "anon insert advisors" on advisors for insert with check (true);

create policy "anon read entries" on entries for select using (true);
create policy "anon write entries" on entries for insert with check (true);
create policy "anon update entries" on entries for update using (true);

create policy "anon read targets" on targets for select using (true);
create policy "anon update targets" on targets for update using (true);

create policy "anon read settings" on settings for select using (true);
create policy "anon write settings" on settings for insert with check (true);
create policy "anon update settings" on settings for update using (true);
