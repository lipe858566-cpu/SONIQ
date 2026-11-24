-- Execute após 20261119_catalog_1_1.sql.
alter table public.tracks add column if not exists release_year integer check (release_year between 1800 and 2200);
alter table public.tracks add column if not exists lrc_text text;
-- A coluna lrc_path permanece para compatibilidade com versões anteriores.
-- Atualiza updated_at em edições.
create or replace function public.soniq_track_touch() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists soniq_track_touch on public.tracks;
create trigger soniq_track_touch before update on public.tracks for each row execute function public.soniq_track_touch();
