# Definição de variáveis
ENV_FILE := .env
# Permite sobrepor o binário de compose via variável de ambiente (COMPOSE_BIN).
COMPOSE_BIN ?= docker compose
# Modo: dev (padrão) ou prod. Use: make MODE=prod up
MODE ?= dev
COMPOSE_FILE := docker-compose.$(MODE).yml
DOCKER_COMPOSE := $(COMPOSE_BIN) --env-file $(ENV_FILE) -f $(COMPOSE_FILE)
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
	$(DOCKER_COMPOSE) exec app /bin/bash || $(DOCKER_COMPOSE) exec app sh

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
	@echo "Uso do Makefile (MODE=dev|prod):"
	@echo "  make env-init                 - Copia .env.example para .env (se não existir)"
	@echo "  make build [MODE=dev|prod]    - Constrói as imagens"
	@echo "  make up [MODE=dev|prod]       - Sobe os containers em segundo plano"
	@echo "  make down [MODE=dev|prod]     - Para os containers"
	@echo "  make restart [MODE=dev|prod]  - Reinicia os containers"
	@echo "  make ps [MODE=dev|prod]       - Mostra status dos containers"
	@echo "  make logs [MODE=dev|prod]     - Segue os logs de todos os serviços"
	@echo "  make exec-app                 - Abre shell no container da aplicação"
	@echo "  make exec-db                  - Abre shell no container do banco (dev)"
	@echo "  make exec-nginx               - Abre shell no container do Nginx"
	@echo "  make artisan cmd=...          - Executa comando Artisan"
	@echo "  make migrate                  - Executa as migrações"
	@echo "  make npm-install              - Instala dependências do NPM"
	@echo "  make npm-dev                  - Sobe o Vite dev server (porta 5173)"
	@echo "  make npm-build                - Compila assets"
	@echo "  make key-generate             - Gera APP_KEY"
	@echo "  make storage-link             - Cria link simbólico do storage"
	@echo "  make prune                    - Remove tudo (imagens/volumes/órfãos)"
	@echo "  make certbot-init domain=example.com email=me@example.com - Emite certificado inicial (prod)"
	@echo "  make ssl-status               - Mostra certificados gerenciados pelo Let's Encrypt"
	@echo "  make ssl-renew                - Renova certificados (webroot) e recarrega o Nginx"
	@echo "  make nginx-reload             - Recarrega o Nginx (sem downtime)"
	@echo "  make deploy                   - Build + Up em produção (usa docker-compose.prod.yml)"
	@echo "  make help                     - Exibe esta ajuda"

# Inicializar/Emitir certificado inicial em produção (necessita DNS apontado)
.PHONY: certbot-init
depends_prod_nginx :=
certbot-init:
	@if [ -z "$(domain)" ] || [ -z "$(email)" ]; then echo "Uso: make certbot-init MODE=prod domain=seu.dominio.com[,outro.com] email=voce@dominio.com"; exit 1; fi
	@DOMAINS_ARGS=""; \
	DOMS="$(domain)"; \
	for d in $${DOMS//,/ }; do DOMAINS_ARGS="$$DOMAINS_ARGS -d $$d"; done; \
	$(COMPOSE_BIN) -f docker-compose.prod.yml run --rm certbot certonly --webroot -w /var/www/certbot $$DOMAINS_ARGS --email $(email) --agree-tos --no-eff-email || true
	@echo "Certificado solicitado. Recarregue o nginx: make MODE=prod nginx-reload"

.PHONY: deploy
deploy:
	@$(COMPOSE_BIN) -f docker-compose.prod.yml pull || true
	@$(COMPOSE_BIN) -f docker-compose.prod.yml up -d --build

.PHONY: deploy-prod
deploy-prod:
	@$(COMPOSE_BIN) -f docker-compose.prod.yml pull || true
	@$(COMPOSE_BIN) -f docker-compose.prod.yml up -d --build

.PHONY: ssl-status
ssl-status:
	@$(COMPOSE_BIN) -f docker-compose.prod.yml run --rm --entrypoint certbot certbot certificates || echo "Nenhum certificado encontrado"

.PHONY: nginx-reload
nginx-reload:
	@echo "[nginx] Rendering config and reloading"
	@$(COMPOSE_BIN) -f docker-compose.prod.yml exec nginx sh -c '
	  if [ -z "$$SERVER_NAME" ]; then
	    echo "SERVER_NAME não definido no contêiner nginx" >&2;
	    exit 1;
	  fi;

	  if [ -f "/etc/nginx/conf.d/default.conf.template" ]; then
	    if [ -f "/etc/letsencrypt/live/$$SERVER_NAME/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$$SERVER_NAME/privkey.pem" ]; then
	      ENABLE_SSL=1;
	    else
	      ENABLE_SSL=0;
	    fi;

	    echo "[nginx] SERVER_NAME=$$SERVER_NAME ENABLE_SSL=$$ENABLE_SSL (reload)";

	    if [ "$$ENABLE_SSL" = "1" ]; then
	      env ENABLE_SSL=$$ENABLE_SSL envsubst "\$$SERVER_NAME \$$ENABLE_SSL" < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf;
	    else
	      awk '\''/#BEGIN_SSL/{flag=1; next} /#END_SSL/{flag=0; next} !flag {print}'\'' /etc/nginx/conf.d/default.conf.template | ENABLE_SSL=0 envsubst "\$$SERVER_NAME \$$ENABLE_SSL" > /etc/nginx/conf.d/default.conf;
	    fi;
	  fi;

	  nginx -t && nginx -s reload'
	@if [ $$? -ne 0 ]; then echo "[nginx] Reload falhou, reiniciando container..."; $(COMPOSE_BIN) -f docker-compose.prod.yml restart nginx; fi

.PHONY: ssl-renew
ssl-renew:
	@$(COMPOSE_BIN) -f docker-compose.prod.yml run --rm --entrypoint certbot certbot renew --webroot -w /var/www/certbot --non-interactive --agree-tos || true
	@$(MAKE) nginx-reload || true

# Comando padrão
.DEFAULT_GOAL := help

# Atalho: prepara ambiente de desenvolvimento rapidamente
.PHONY: dev-quickstart
dev-quickstart:
	@$(MAKE) env-init
	@$(MAKE) build
	@$(MAKE) up
	@$(MAKE) permissions || true
	@$(MAKE) key-generate || true
	@$(MAKE) storage-link || true
	@$(MAKE) npm-install || true
	@echo "Ambiente de desenvolvimento pronto. Acesse http://localhost"