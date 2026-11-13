
-- SONIQ 1.0.0 BETA
-- Banco de dados, perfis, favoritos, playlists e fotos

-- 1. PERFIS
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Ouvinte SONIQ',
  username text not null default '@soniq',
  bio text not null default '',
  avatar_path text,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Usuário lê seu perfil"
on public.profiles for select to authenticated
using ((select auth.uid()) = id);

create policy "Usuário cria seu perfil"
on public.profiles for insert to authenticated
with check ((select auth.uid()) = id);

create policy "Usuário edita seu perfil"
on public.profiles for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);


-- 2. MÚSICAS FAVORITAS
create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  track_id text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, track_id)
);

alter table public.favorites enable row level security;

create policy "Ler favoritos próprios"
on public.favorites for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Adicionar favoritos próprios"
on public.favorites for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "Remover favoritos próprios"
on public.favorites for delete to authenticated
using ((select auth.uid()) = user_id);


-- 3. PLAYLISTS
create table if not exists public.playlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

alter table public.playlists enable row level security;

create policy "Ler playlists próprias"
on public.playlists for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Criar playlists próprias"
on public.playlists for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "Editar playlists próprias"
on public.playlists for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Excluir playlists próprias"
on public.playlists for delete to authenticated
using ((select auth.uid()) = user_id);


-- 4. MÚSICAS DAS PLAYLISTS
create table if not exists public.playlist_tracks (
  playlist_id uuid not null references public.playlists(id) on delete cascade,
  track_id text not null,
  position integer not null default 0,
  primary key (playlist_id, track_id)
);

alter table public.playlist_tracks enable row level security;

create policy "Ler faixas de playlists próprias"
on public.playlist_tracks for select to authenticated
using (
  exists (
    select 1 from public.playlists p
    where p.id = playlist_id
    and p.user_id = (select auth.uid())
  )
);

create policy "Adicionar faixas às playlists próprias"
on public.playlist_tracks for insert to authenticated
with check (
  exists (
    select 1 from public.playlists p
    where p.id = playlist_id
    and p.user_id = (select auth.uid())
  )
);

create policy "Remover faixas de playlists próprias"
on public.playlist_tracks for delete to authenticated
using (
  exists (
    select 1 from public.playlists p
    where p.id = playlist_id
    and p.user_id = (select auth.uid())
  )
);


-- 5. ARMAZENAMENTO DE FOTOS
-- Bucket público: as fotos enviadas poderão ser visualizadas
-- por qualquer pessoa que tenha o endereço da imagem.

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'avatars', 'avatars', true, 5242880,
  array['image/jpeg', 'image/png']
)
on conflict (id) do update
set public = true,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg', 'image/png'];


-- 6. SEGURANÇA DAS FOTOS
create policy "Avatar público para exibição"
on storage.objects for select to public
using (bucket_id = 'avatars');

create policy "Enviar avatar próprio"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Atualizar avatar próprio"
on storage.objects for update to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Excluir avatar próprio"
on storage.objects for delete to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
