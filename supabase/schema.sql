-- Finanças Edson Mendes: execute no SQL Editor do seu próprio projeto Supabase.
-- ATENÇÃO: mantenha cadastro público desabilitado no Auth; convide clientes manualmente.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'client' check (role in ('admin','client')),
  access_status text not null default 'pending' check (access_status in ('pending','active','blocked')),
  created_at timestamptz not null default now()
);
create table if not exists public.financial_entries (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  description text not null check (char_length(description) between 1 and 200),
  entry_type text not null check (entry_type in ('income','expense')),
  amount numeric(14,2) not null check (amount > 0),
  due_date date,
  status text not null default 'pending' check (status in ('pending','paid','received','cancelled')),
  created_at timestamptz not null default now()
);
create index if not exists financial_entries_owner_idx on public.financial_entries(owner_id,created_at desc);
create or replace function public.new_user_profile() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,display_name,role,access_status)
 values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),'client','pending')
 on conflict(id) do nothing;
 return new;
end $$;
drop trigger if exists auth_user_created_financas on auth.users;
create trigger auth_user_created_financas after insert on auth.users for each row execute function public.new_user_profile();
-- A função abaixo consulta somente a identidade autenticada; não aceita user_id fornecido pelo navegador.
create or replace function public.is_financas_admin() returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles where id = (select auth.uid()) and role='admin' and access_status='active')
$$;
create or replace function public.financas_access_active() returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.profiles where id = (select auth.uid()) and access_status='active')
$$;
alter table public.profiles enable row level security;
alter table public.financial_entries enable row level security;
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated using(id = (select auth.uid()) or (select public.is_financas_admin()));
-- Apenas administrador ativo pode liberar ou bloquear; cliente não pode promover a si mesmo.
drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles for update to authenticated using((select public.is_financas_admin())) with check((select public.is_financas_admin()));
drop policy if exists entries_read on public.financial_entries;
create policy entries_read on public.financial_entries for select to authenticated using(owner_id=(select auth.uid()) and (select public.financas_access_active()));
drop policy if exists entries_insert on public.financial_entries;
create policy entries_insert on public.financial_entries for insert to authenticated with check(owner_id=(select auth.uid()) and (select public.financas_access_active()));
drop policy if exists entries_update on public.financial_entries;
create policy entries_update on public.financial_entries for update to authenticated using(owner_id=(select auth.uid()) and (select public.financas_access_active())) with check(owner_id=(select auth.uid()) and (select public.financas_access_active()));
drop policy if exists entries_delete on public.financial_entries;
create policy entries_delete on public.financial_entries for delete to authenticated using(owner_id=(select auth.uid()) and (select public.financas_access_active()));
-- Configure o administrador UMA VEZ pelo SQL Editor, substituindo o UUID abaixo pelo auth.users.id correto:
-- update public.profiles set role='admin', access_status='active' where id='COLOQUE-AQUI-O-UUID-DO-ADMIN';
-- Nunca exponha a service_role key no GitHub ou navegador.
