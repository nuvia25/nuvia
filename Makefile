# Definição de variáveis
ENV_FILE := .env
# Permite sobrepor o binário de compose via variável de ambiente (COMPOSE_BIN).
COMPOSE_BIN ?= docker compose
DOCKER_COMPOSE := $(COMPOSE_BIN) --env-file $(ENV_FILE) -f docker-compose.dev.yml
DOCKER_COMPOSE_EXEC := $(DOCKER_COMPOSE) exec app

.PHONY: build
build:
	@which docker >/dev/null 2>&1 || (echo "Docker não está instalado!" && exit 1)
	$(DOCKER_COMPOSE) build

.PHONY: up
up:
	@test -f $(ENV_FILE) || (echo "Arquivo $(ENV_FILE) não encontrado! Rode: make env-init" && exit 1)
	$(DOCKER_COMPOSE) up -d

.PHONY: down
down:
	$(DOCKER_COMPOSE) down

.PHONY: prune
prune:
	$(DOCKER_COMPOSE) down --rmi all -v --remove-orphans

.PHONY: restart
restart:
	$(DOCKER_COMPOSE) restart

.PHONY: ps
ps:
	$(DOCKER_COMPOSE) ps

.PHONY: logs
logs:
	$(DOCKER_COMPOSE) logs -f

.PHONY: sh
sh:
	$(DOCKER_COMPOSE) exec app /bin/bash

.PHONY: exec-app
exec-app:
	$(DOCKER_COMPOSE) exec app /bin/bash

.PHONY: exec-db
exec-db:
	$(DOCKER_COMPOSE) exec db sh

.PHONY: exec-nginx
exec-nginx:
	$(DOCKER_COMPOSE) exec nginx sh

.PHONY: artisan
artisan:
	@if [ -z "$(cmd)" ]; then echo "Uso: make artisan cmd='migrate'"; exit 1; fi
	$(DOCKER_COMPOSE_EXEC) php artisan $(cmd)

.PHONY: migrate
migrate:
	$(DOCKER_COMPOSE_EXEC) php artisan migrate

.PHONY: migrate-fresh
migrate-fresh:
	$(DOCKER_COMPOSE_EXEC) php artisan migrate:fresh

.PHONY: seed
seed:
	$(DOCKER_COMPOSE_EXEC) php artisan db:seed

.PHONY: composer-install
composer-install:
	$(DOCKER_COMPOSE_EXEC) composer install

.PHONY: composer-update
composer-update:
	$(DOCKER_COMPOSE_EXEC) composer update

.PHONY: npm-install
npm-install:
	$(DOCKER_COMPOSE_EXEC) npm ci || $(DOCKER_COMPOSE_EXEC) npm install

.PHONY: npm-build
npm-build:
	$(DOCKER_COMPOSE_EXEC) npm run build

.PHONY: npm-dev
npm-dev:
	$(DOCKER_COMPOSE_EXEC) npm run dev -- --host

.PHONY: key-generate
key-generate:
	$(DOCKER_COMPOSE_EXEC) php artisan key:generate

.PHONY: permissions
permissions:
	$(DOCKER_COMPOSE_EXEC) sh -lc 'mkdir -p storage/framework/{cache,sessions,views,testing,cache/data} bootstrap/cache; chown -R laravel:laravel storage bootstrap/cache || chown -R www-data:www-data storage bootstrap/cache || true; find storage -type d -exec chmod 775 {} \; ; find storage -type f -exec chmod 664 {} \; ; chmod -R ug+rwX bootstrap/cache'


.PHONY: storage-link
storage-link:
	$(DOCKER_COMPOSE_EXEC) php artisan storage:link

.PHONY: test
test:
	$(DOCKER_COMPOSE_EXEC) php vendor/bin/pest --colors=always

.PHONY: env-init
env-init:
	@test -f $(ENV_FILE) || cp .env.example $(ENV_FILE)
	@echo "Ajuste seu .env para Docker (DB_HOST=db, REDIS_HOST=redis, MAIL_HOST=mailpit) se necessário."

.PHONY: help
help:
	@echo "Uso do Makefile:"
	@echo "  make env-init           - Copia .env.example para .env (se não existir)"
	@echo "  make build              - Constrói as imagens"
	@echo "  make up                 - Sobe os containers em segundo plano"
	@echo "  make down               - Para os containers"
	@echo "  make restart            - Reinicia os containers"
	@echo "  make ps                 - Mostra status dos containers"
	@echo "  make logs               - Segue os logs de todos os serviços"
	@echo "  make exec-app           - Abre bash no container da aplicação"
	@echo "  make exec-db            - Abre shell no container do banco"
	@echo "  make exec-nginx         - Abre shell no container do Nginx"
	@echo "  make artisan cmd=...    - Executa comando Artisan (ex: make artisan cmd='migrate')"
	@echo "  make migrate            - Executa as migrações"
	@echo "  make migrate-fresh      - Recria o banco e migra"
	@echo "  make seed               - Executa os seeders"
	@echo "  make composer-install   - Instala dependências do Composer"
	@echo "  make composer-update    - Atualiza dependências do Composer"
	@echo "  make npm-install        - Instala dependências do NPM"
	@echo "  make npm-dev            - Sobe o Vite dev server (porta 5173)"
	@echo "  make npm-build          - Compila assets"
	@echo "  make key-generate       - Gera APP_KEY"
	@echo "  make storage-link       - Cria link simbólico do storage"
	@echo "  make prune              - Remove tudo (imagens/volumes/órfãos)"
	@echo "  make help               - Exibe esta ajuda"

# Comando padrão
.DEFAULT_GOAL := help