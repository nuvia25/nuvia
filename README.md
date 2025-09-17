# MagicAI - Ambiente de Desenvolvimento e Produção com Docker

Este repositório contém uma aplicação Laravel 10. Este guia descreve como preparar e executar o ambiente de desenvolvimento e de produção usando Docker, Docker Compose e o Makefile fornecido.

## Requisitos
- Docker (Engine + Compose Plugin)
- Make (GNU Make)

## Primeiros passos
- Modo fácil (recomendado):
  - make dev-quickstart
  - A aplicação sobe em http://localhost

- Passo a passo manual:
  1. Copie o arquivo de ambiente (se ainda não existir):
     - make env-init
  2. Ajuste o .env para uso com Docker (recomendado):
     - DB_HOST=db
     - REDIS_HOST=redis (se for usar Redis)
     - MAIL_HOST=mailpit
     - Opcional: APP_URL=http://localhost
  3. Construa as imagens e suba os containers:
     - make build
     - make up
  4. Gere a chave da aplicação (se necessário) e crie o link do storage:
     - make key-generate
     - make storage-link
  5. Instale dependências do PHP e do Node e suba o Vite (assets):
     - make composer-install
     - make npm-install
     - make npm-dev  # Vite em http://localhost:5173

A aplicação estará disponível em http://localhost (Nginx -> PHP-FPM). O MySQL expõe a porta configurada em DB_PORT (padrão 3306). Mailpit em http://localhost:8025 e SMTP em 1025.

## Serviços (docker-compose.dev.yml)
- app: Contém PHP-FPM 8.2, Composer, Node/NPM e Xdebug habilitável (target de desenvolvimento). Porta 9000 (FPM) e 5173 (Vite) expostas.
- nginx: Servidor web Nginx servindo /public. Porta 80 exposta no host (APP_PORT pode customizar). Usa template docker/nginx/dev.conf.template (renderizado via envsubst), aceitando SERVER_NAME do ambiente.
- db: MySQL 8.0 com volume persistente. Use host db a partir da aplicação.
- redis: Redis 7 (opcional). Use host redis.
- mailpit: Captura e visualiza e-mails (http://localhost:8025 / SMTP 1025).

## Produção (docker-compose.prod.yml)
- app: Builda a imagem no target production (multistage). Não inclui Xdebug; Composer sem dev e assets buildados.
- nginx: Servidor Nginx HTTP‑only (porta 80) com configuração estática. Monta o arquivo docker/nginx/prod.http.conf.template diretamente em /etc/nginx/conf.d/default.conf (sem templating/envsubst), usando server_name _.
- Banco de dados: externo (configure DB_HOST, DB_DATABASE, DB_USERNAME, DB_PASSWORD no .env do servidor).

### Fluxo recomendado (deploy)
1. Ajuste variáveis do banco no servidor (DB_HOST, DB_DATABASE, DB_USERNAME, DB_PASSWORD) conforme sua infraestrutura.
2. No servidor, construa e suba a stack (HTTP‑only):
   - docker compose -f docker-compose.prod.yml up -d --build

### Próximos deploys
- Via Make: `make deploy` ou `make deploy-prod`.
- Via GitHub Actions: workflow `.github/workflows/deploy.yml`.

### Verificação pós-deploy
- docker compose -f docker-compose.prod.yml ps
- docker compose -f docker-compose.prod.yml logs -f nginx
- docker compose -f docker-compose.prod.yml logs -f app

## Makefile - Comandos úteis
- make env-init: Copia .env.example para .env (se não existir) e lembra ajustes de Docker.
- make build: Constrói as imagens.
- make up / make down / make restart / make ps / make logs
- make exec-app: Abre bash no container da aplicação.
- make exec-db / make exec-nginx: Shell nos serviços.
- make artisan cmd="migrate": Executa um comando Artisan.
- make migrate / make migrate-fresh / make seed
- make composer-install / make composer-update
- make npm-install / make npm-dev / make npm-build
- make key-generate / make storage-link
- make prune: Remove containers, volumes e imagens relacionadas ao compose.

## Fluxo de desenvolvimento
1. Sobe ambiente: make up
2. Ajuste as permissões: make permissions
2. Rodar migrações/seeders: make migrate ou make seed
3. Desenvolver assets: make npm-dev (com --host para permitir acesso externo)
4. Rodar testes: make test

## GitHub Actions - Deploy automático
Crie os seguintes secrets no repositório:
- SSH_HOST: host/IP do servidor
- SSH_USER: usuário para SSH
- SSH_PRIVATE_KEY: chave privada (formato OpenSSH) com acesso ao servidor
- KNOWN_HOSTS: saída de `ssh-keyscan -H seu-servidor` para verificação de host
- APP_PATH: caminho no servidor onde o repo está (ex: /var/www/nuvia)
- GH_TOKEN: token com permissão de leitura do repositório (para git pull via HTTPS)
- SERVER_NAME: opcional. Hostname público (sem http/https). Se vazio, o workflow testa via IP (SSH_HOST).

O workflow em .github/workflows/deploy.yml fará SSH, dará git pull e rodará `make deploy-prod`. O pipeline testa conectividade HTTP.

Obs.: Em produção, o Nginx roda apenas em HTTP (porta 80). Não há configuração de HTTPS/Certbot neste stack.

## Observações importantes
- Variáveis de ambiente: O docker-compose fornece overrides para DB_HOST, REDIS_HOST e MAIL_HOST diretamente no serviço app. Isso normalmente tem precedência sobre .env dentro do container. Ainda assim, recomenda-se ajustar o seu .env conforme seção "Primeiros passos" para evitar confusão.
- Permissões: O Dockerfile já define permissões adequadas para storage/ e bootstrap/cache. Em Linux, se precisar, ajuste APP_UID/APP_USER no seu .env para casar com seu usuário local (padrão 1000/laravel).
- Xdebug: Instalado no target de desenvolvimento. Configure sua IDE para ouvir conexões remotas; o arquivo docker/php/xdebug.ini usa host.docker.internal (funciona em Windows e Linux recentes). Ative definindo XDEBUG_MODE=debug no serviço app ou no .env.
- Vite/HMR: Em Windows/macOS o compose já define CHOKIDAR_USEPOLLING= true e WATCHPACK_POLLING= true para detecção de mudanças via volume. O make npm-dev usa --host para expor no localhost.
- Compose no Windows: Se sua instalação usa o binário antigo docker-compose (e não docker compose), execute os comandos do Make com COMPOSE_BIN="docker-compose" make up (ou export COMPOSE_BIN= docker-compose).
- Fim de linha: Repositório força LF para scripts/config (via .gitattributes) para evitar problemas em Windows.

## Troubleshooting
- Banco não conecta: Verifique se DB_HOST=db e credenciais (DB_DATABASE, DB_USERNAME, DB_PASSWORD) no seu .env. As variáveis padrão do compose usam magicai/root/secret (ajustável).
- Permissões de arquivos: Se tiver problemas no host, ajuste UID/GID passados em docker-compose (args user/uid) para corresponder ao seu usuário local.
- Portas em uso: Ajuste APP_PORT, DB_PORT e demais portas em seu .env antes de executar make up.

## Licença
MIT