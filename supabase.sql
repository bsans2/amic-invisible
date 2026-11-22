-- Amic Invisible · configuració de Supabase (versió multiusuari)
-- SQL Editor → New query → Run. Es pot executar més d'una vegada sense errors.

create table if not exists events(
  id uuid primary key,
  name text,
  data jsonb not null default '{}',
  updated_at timestamptz default now()
);
-- Propietari de cada esdeveniment (l'usuari que l'ha creat)
alter table events add column if not exists owner uuid default auth.uid() references auth.users(id) on delete cascade;

create table if not exists links(
  token text primary key,
  event_id uuid not null references events(id) on delete cascade,
  code text,
  payload jsonb not null
);

-- Llista d'administradors (sense polítiques: només s'hi accedeix des de les funcions de sota)
create table if not exists admins(user_id uuid primary key references auth.users(id) on delete cascade);
alter table admins enable row level security;

grant select, insert, update, delete on table events, links to authenticated;

create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from admins where user_id = auth.uid())
$$;
revoke all on function is_admin() from public;
grant execute on function is_admin() to authenticated;

-- Cada usuari només veu i modifica els seus esdeveniments; l'administrador els veu tots.
alter table events enable row level security;
alter table links  enable row level security;
drop policy if exists admin_events on events;
drop policy if exists admin_links  on links;
drop policy if exists events_rw    on events;
drop policy if exists links_rw     on links;
create policy events_rw on events for all to authenticated
  using (owner = auth.uid() or is_admin()) with check (owner = auth.uid() or is_admin());
create policy links_rw on links for all to authenticated
  using (exists(select 1 from events e where e.id = event_id and (e.owner = auth.uid() or is_admin())))
  with check (exists(select 1 from events e where e.id = event_id and (e.owner = auth.uid() or is_admin())));

-- Els participants només poden cridar aquesta funció amb el seu enllaç secret.
create or replace function get_link(p_token text, p_code text default null)
returns jsonb language sql security definer set search_path = public as $$
  select case when code is not null and p_code is distinct from code
              then jsonb_build_object('need', true)
              else payload end
  from links where token = p_token
$$;
revoke all on function get_link(text, text) from public;
grant execute on function get_link(text, text) to anon, authenticated;

-- Resum per al panell d'administració (només retorna dades si l'usuari és administrador).
create or replace function admin_overview() returns jsonb
language sql security definer set search_path = public as $$
  select case when is_admin() then jsonb_build_object(
    'users', (select count(*) from auth.users),
    'events', coalesce((select jsonb_agg(jsonb_build_object(
        'id', e.id, 'name', e.name, 'owner', u.email,
        'n', jsonb_array_length(coalesce(e.data->'p', '[]'::jsonb)),
        'drawn', jsonb_typeof(e.data->'res') = 'object',
        'pub', coalesce((e.data->>'pub')::boolean, false),
        'upd', e.updated_at) order by e.updated_at desc)
      from events e left join auth.users u on u.id = e.owner), '[]'::jsonb)) end
$$;
revoke all on function admin_overview() from public;
grant execute on function admin_overview() to authenticated;

-- Per fer-te administrador/a: canvia el correu, treu els "--" i executa NOMÉS aquesta línia una vegada.
-- insert into admins(user_id) select id from auth.users where email = 'EL_TEU_CORREU' on conflict do nothing;
