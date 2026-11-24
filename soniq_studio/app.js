'use strict';
const $ = id => document.getElementById(id);
let db, editing = null, tracks = [];
const show = (id, yes) => $(id).classList.toggle('hidden', !yes);
const message = text => { $('message').textContent = text; };
const fail = error => message(`Erro: ${error?.message || error}`);
const required = (result) => { if (result.error) throw result.error; return result.data; };
const ext = file => (file.name.split('.').pop() || 'bin').toLowerCase();
async function upload(bucket, file) {
  if (!file) return null;
  const path = `${crypto.randomUUID()}.${ext(file)}`;
  required(await db.storage.from(bucket).upload(path, file, { contentType: file.type || undefined, upsert: false }));
  return path;
}
async function connect() {
  try {
    const url = $('url').value.trim(), key = $('key').value.trim();
    if (!/^https:\/\/.+\.supabase\.co\/?$/.test(url) || !key) throw Error('Informe URL Supabase e chave publicável válidas.');
    db = window.supabase.createClient(url, key);
    sessionStorage.setItem('soniq-url', url);
    sessionStorage.setItem('soniq-key', key);
    show('setup', false); show('login', true);
    await checkSession();
  } catch (e) { fail(e); }
}
async function checkSession() {
  const {data: {user}, error} = await db.auth.getUser();
  if (error || !user) { show('admin', false); show('login', true); return; }
  const admin = required(await db.from('admins').select('user_id').eq('user_id', user.id).maybeSingle());
  if (!admin) { await db.auth.signOut(); throw Error('Esta conta não possui permissão de administrador.'); }
  show('login', false); show('admin', true); await refresh();
}
async function refresh() {
  try {
    tracks = required(await db.from('tracks').select('*').order('created_at', {ascending:false}).limit(500));
    $('count').textContent = `(${tracks.length})`;
    $('tracks').replaceChildren();
    for (const track of tracks) {
      const row = document.createElement('div'); row.className = 'track';
      const name = document.createElement('strong'); name.textContent = `${track.title} • ${track.artist}`;
      const meta = document.createElement('small'); meta.textContent = `${track.published ? 'Publicado' : 'Rascunho'} | ${track.genre || 'Sem gênero'}`;
      const edit = document.createElement('button'); edit.textContent = 'Editar'; edit.onclick = () => editTrack(track);
      const remove = document.createElement('button'); remove.textContent = 'Excluir'; remove.className = 'danger'; remove.onclick = () => deleteTrack(track);
      row.append(name, meta, document.createElement('br'), edit, remove); $('tracks').append(row);
    }
  } catch (e) { fail(e); }
}
function editTrack(track) {
  editing = track; $('formTitle').textContent = 'Editar música';
  for (const field of ['title','artist','album','genre']) $(field).value = track[field] || '';
  $('year').value = track.release_year || ''; $('duration').value = track.duration_seconds || 0;
  $('lrc').value = track.lrc_text || ''; $('published').checked = track.published;
  window.scrollTo({top:0,behavior:'smooth'});
}
function cancelEdit() {
  editing = null; $('trackForm').reset(); $('formTitle').textContent = 'Cadastrar música';
}
async function deleteTrack(track) {
  if (!confirm(`Excluir definitivamente "${track.title}" do catálogo?`)) return;
  try {
    required(await db.from('tracks').delete().eq('id', track.id));
    // Os objetos ficam no Storage para evitar perda acidental; remova-os manualmente após conferir referências.
    message('Registro excluído. Confira arquivos órfãos no Storage.'); await refresh();
  } catch (e) { fail(e); }
}
async function saveTrack(event) {
  event.preventDefault(); $('save').disabled = true;
  try {
    const audio = $('audio').files[0], cover = $('cover').files[0];
    if (!editing && !audio) throw Error('Selecione um arquivo de áudio para a nova música.');
    const audioPath = await upload('music', audio), coverPath = await upload('covers', cover);
    const row = {
      title:$('title').value.trim(), artist:$('artist').value.trim(), album:$('album').value.trim(),
      genre:$('genre').value.trim(), duration_seconds:Number($('duration').value)||0,
      published:$('published').checked, lrc_text:$('lrc').value,
      release_year:$('year').value ? Number($('year').value) : null,
    };
    if (audioPath) row.audio_path = audioPath;
    if (coverPath) row.cover_path = coverPath;
    if (editing) required(await db.from('tracks').update(row).eq('id', editing.id));
    else required(await db.from('tracks').insert(row));
    cancelEdit(); message('Música salva. Atualize o catálogo no aplicativo para visualizar.'); await refresh();
  } catch(e) { fail(e); } finally { $('save').disabled = false; }
}
$('connect').onclick = connect;
$('signIn').onclick = async () => { try { required(await db.auth.signInWithPassword({email:$('email').value,password:$('password').value})); await checkSession(); } catch(e) { fail(e); } };
$('logout').onclick = async () => { await db.auth.signOut(); show('admin',false); show('login',true); };
$('refresh').onclick = refresh;
$('cancel').onclick = cancelEdit;
$('trackForm').onsubmit = saveTrack;
if (sessionStorage.getItem('soniq-url')) { $('url').value = sessionStorage.getItem('soniq-url'); $('key').value = sessionStorage.getItem('soniq-key') || ''; }

if (!sessionStorage.getItem('soniq-url')) { $('url').value = window.SONIQ_CONFIG.url; $('key').value = window.SONIQ_CONFIG.publicKey; }
