# SONIQ Studio (protótipo funcional)

1. Execute as migrações `20261119_catalog_1_1.sql` e `20261122_studio_fields.sql` no SQL Editor do Supabase.
2. Cadastre seu UUID em `public.admins` usando o SQL Editor com privilégios de proprietário.
3. Hospede esta pasta como site estático HTTPS (ou execute `python -m http.server 8080` para teste local).
4. Abra `index.html`, informe a URL do Supabase e a chave **publicável**, entre com sua conta administradora.
5. Faça upload do áudio e capa, preencha metadados e marque Publicar.

O painel usa a autenticação Supabase e RLS. Não inclui credenciais administrativas. A chave publicável fica apenas na sessão do navegador. O painel depende do CDN do supabase-js. Excluir registros não remove arquivos do Storage; faça limpeza de órfãos com cautela. A publicação aparece na próxima consulta/atualização do catálogo pelo app, não há push em tempo real garantido.

Limitações: ainda não existe visualização de capa, paginação além dos 500 registros mais recentes, nem gestão de usuários. As letras LRC são armazenadas no campo `lrc_text`, mas o app ainda não as exibe. Faça teste de upload e reprodução no seu Supabase antes de considerar produção.
