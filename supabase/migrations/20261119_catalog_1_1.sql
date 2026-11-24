-- SONIQ 1.1: catálogo próprio, administradores e armazenamento de áudio.

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = (select auth.uid()));
$$;

create policy "Administrador vê a si mesmo"
on public.admins for select to authenticated
using (user_id = (select auth.uid()));

create table if not exists public.tracks (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 200),
  artist text not null check (char_length(artist) between 1 and 200),
  album text not null default '',
  genre text not null default '',
  duration_seconds integer not null default 0 check (duration_seconds >= 0),
  audio_path text not null,
  cover_path text,
  lrc_path text,
  published boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists tracks_published_created_idx on public.tracks (published, created_at desc);

alter table public.tracks enable row level security;

create policy "Catálogo publicado visível para usuários"
on public.tracks for select to authenticated
using (published or public.is_admin());

create policy "Administradores inserem músicas"
on public.tracks for insert to authenticated
with check (public.is_admin());

create policy "Administradores editam músicas"
on public.tracks for update to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "Administradores excluem músicas"
on public.tracks for delete to authenticated
using (public.is_admin());

-- Áudio privado (URLs assinadas), capas e letras.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('music', 'music', false, 104857600,
        array['audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/ogg', 'audio/flac', 'audio/wav', 'audio/x-wav'])
on conflict (id) do update set public = false;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('covers', 'covers', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true;

create policy "Usuários autenticados leem áudio"
on storage.objects for select to authenticated
using (bucket_id = 'music');

create policy "Capas públicas"
on storage.objects for select to public
using (bucket_id = 'covers');

create policy "Administradores gerenciam áudio"
on storage.objects for all to authenticated
using (bucket_id in ('music', 'covers') and public.is_admin())
with check (bucket_id in ('music', 'covers') and public.is_admin());

-- Para tornar uma conta administradora (execute no SQL Editor, com o UUID real):
-- insert into public.admins (user_id) values ('00000000-0000-0000-0000-000000000000');
