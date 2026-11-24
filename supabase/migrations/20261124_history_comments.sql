create table public.playback_history (
 user_id uuid references auth.users(id) on delete cascade,
 track_id uuid references public.tracks(id) on delete cascade,
 played_at timestamptz not null default now(),
 primary key(user_id,track_id)
);
alter table public.playback_history enable row level security;
create policy history_owner on public.playback_history for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create table public.track_comments (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 track_id uuid not null references public.tracks(id) on delete cascade,
 body text not null check (char_length(trim(body)) between 1 and 1000),
 created_at timestamptz not null default now()
);
alter table public.track_comments enable row level security;
create policy comments_read on public.track_comments for select to authenticated using (exists(select 1 from public.tracks t where t.id = track_id and t.published));
create policy comments_insert on public.track_comments for insert to authenticated with check (auth.uid() = user_id and exists(select 1 from public.tracks t where t.id = track_id and t.published));
create policy comments_delete on public.track_comments for delete to authenticated using (auth.uid() = user_id);
create table public.artists (id uuid primary key default gen_random_uuid(), name text not null unique);
alter table public.artists enable row level security;
create policy artists_read on public.artists for select to authenticated using (true);
create policy artists_admin on public.artists for all to authenticated using (public.is_admin()) with check (public.is_admin());
create function public.create_soniq_profile() returns trigger language plpgsql security definer set search_path = public as $$
begin
 insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','Ouvinte SONIQ')) on conflict(id) do nothing;
 return new;
end; $$;
create trigger soniq_new_user after insert on auth.users for each row execute function public.create_soniq_profile();
drop policy "Usuários autenticados leem áudio" on storage.objects;
create policy published_audio on storage.objects for select to authenticated using (bucket_id = 'music' and (public.is_admin() or exists(select 1 from public.tracks t where t.audio_path = name and t.published)));
