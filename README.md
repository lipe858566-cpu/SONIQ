# SONIQ

O SONIQ é um aplicativo de música para Android desenvolvido em Flutter. O projeto surgiu do meu interesse por desenvolvimento de aplicativos e da ideia de criar uma plataforma de música com identidade própria.

O aplicativo conta com um catálogo próprio, gerenciado através do SONIQ Studio, um painel administrativo desenvolvido para facilitar o cadastro de músicas, artistas, capas e letras.

## Funcionalidades

- Reprodução de músicas em segundo plano
- Criação e gerenciamento de playlists
- Músicas favoritas
- Pesquisa de músicas e artistas
- Histórico de reprodução
- Equalizador e Bass Boost
- Letras sincronizadas
- Downloads para reprodução offline
- Comentários nas músicas
- Personalização do perfil

## Tecnologias utilizadas

- Flutter
- Dart
- Supabase
- PostgreSQL
- Kotlin
- HTML, CSS e JavaScript

## SONIQ Studio

O SONIQ Studio é o painel administrativo do aplicativo. Através dele, é possível gerenciar o catálogo musical e disponibilizar novos conteúdos no SONIQ.

O armazenamento dos arquivos, a autenticação e o banco de dados utilizam o Supabase.

## Executando o projeto

É necessário ter o Flutter SDK instalado e um projeto configurado no Supabase.

Após clonar o repositório, instale as dependências com:

`flutter pub get`

Configure as credenciais públicas do Supabase no arquivo `config.json` e execute:

`flutter run --dart-define-from-file=config.json`

## Versão

SONIQ 1.1

O projeto está em desenvolvimento contínuo, com melhorias de desempenho, interface e reprodução de áudio.

## Desenvolvedor

Felipe Gabriel Barbosa Dionizio

Estudante de Ciência da Computação, com interesse em desenvolvimento de software e tecnologia.

GitHub: https://github.com/Lipe858566-cpu