create function public.soniq_comments(song_id uuid)
returns table(id uuid,user_id uuid,body text,created_at timestamptz,display_name text,avatar_path text)
language sql stable security definer set search_path = '' as $$
 select c.id,c.user_id,c.body,c.created_at,p.display_name,p.avatar_path
 from public.track_comments c join public.profiles p on p.id=c.user_id
 join public.tracks t on t.id=c.track_id
 where auth.uid() is not null and t.published and c.track_id=song_id
 order by c.created_at desc limit 200;
$$;
revoke all on function public.soniq_comments(uuid) from public;
grant execute on function public.soniq_comments(uuid) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit) values ('lyrics','lyrics',false,1048576) on conflict(id) do nothing;
create policy lyrics_read on storage.objects for select to authenticated using (bucket_id='lyrics' and (public.is_admin() or exists(select 1 from public.tracks t where t.lrc_path=name and t.published)));
create policy lyrics_admin on storage.objects for all to authenticated using (bucket_id='lyrics' and public.is_admin()) with check (bucket_id='lyrics' and public.is_admin());
