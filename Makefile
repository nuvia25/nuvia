# Definição de variáveis
ENV_FILE := .env
COMPOSE_BIN ?= docker compose
MODE ?= dev
COMPOSE_FILE := docker-compose.$(MODE).yml
DOCKER_COMPOSE := $(COMPOSE_BIN) --env-file $(ENV_FILE) -f $(COMPOSE_FILE)
DOCKER_COMPOSE_EXEC := $(DOCKER_COMPOSE) exec app
PROD_COMPOSE := $(COMPOSE_BIN) -f docker-compose.prod.yml

# Cores para output
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
BLUE := \033[34m
RESET := \033[0m

# Comandos básicos de container
.PHONY: build up down restart ps logs
build:
	@which docker >/dev/null 2>&1 || (echo "$(RED)Docker não está instalado!$(RESET)" && exit 1)
	@echo "$(BLUE)[build]$(RESET) Construindo imagens para modo $(MODE)..."
	$(DOCKER_COMPOSE) build

up:
	@test -f $(ENV_FILE) || (echo "$(RED)Arquivo $(ENV_FILE) não encontrado! Rode: make env-init$(RESET)" && exit 1)
	@echo "$(BLUE)[up]$(RESET) Subindo containers em modo $(MODE)..."
	$(DOCKER_COMPOSE) up -d

down:
	@echo "$(BLUE)[down]$(RESET) Parando containers..."
	$(DOCKER_COMPOSE) down

restart:
	@echo "$(BLUE)[restart]$(RESET) Reiniciando containers..."
	$(DOCKER_COMPOSE) restart

ps:
	$(DOCKER_COMPOSE) ps

logs:
	$(DOCKER_COMPOSE) logs -f

# Comandos de acesso aos containers
.PHONY: sh exec-app exec-db exec-nginx
sh:
	$(DOCKER_COMPOSE) exec app /bin/bash || $(DOCKER_COMPOSE) exec app sh

exec-app:
	$(DOCKER_COMPOSE) exec app /bin/bash

exec-db:
	$(DOCKER_COMPOSE) exec db sh

exec-nginx:
	$(DOCKER_COMPOSE) exec nginx sh

# Comandos Laravel/PHP
.PHONY: artisan migrate migrate-fresh seed composer-install composer-update
artisan:
	@if [ -z "$(cmd)" ]; then echo "$(RED)Uso: make artisan cmd='migrate'$(RESET)"; exit 1; fi
	$(DOCKER_COMPOSE_EXEC) php artisan $(cmd)

migrate:
	@echo "$(BLUE)[migrate]$(RESET) Executando migrações..."
	$(DOCKER_COMPOSE_EXEC) php artisan migrate

migrate-fresh:
	@echo "$(YELLOW)[migrate-fresh]$(RESET) Recriando banco de dados..."
	$(DOCKER_COMPOSE_EXEC) php artisan migrate:fresh

seed:
	@echo "$(BLUE)[seed]$(RESET) Populando banco de dados..."
	$(DOCKER_COMPOSE_EXEC) php artisan db:seed

composer-install:
	@echo "$(BLUE)[composer]$(RESET) Instalando dependências PHP..."
	$(DOCKER_COMPOSE_EXEC) composer install

composer-update:
	@echo "$(BLUE)[composer]$(RESET) Atualizando dependências PHP..."
	$(DOCKER_COMPOSE_EXEC) composer update

# Comandos Node.js/NPM
.PHONY: npm-install npm-build npm-dev
npm-install:
	@echo "$(BLUE)[npm]$(RESET) Instalando dependências JavaScript..."
	$(DOCKER_COMPOSE_EXEC) npm ci || $(DOCKER_COMPOSE_EXEC) npm install

npm-build:
	@echo "$(BLUE)[npm]$(RESET) Compilando assets para produção..."
	$(DOCKER_COMPOSE_EXEC) npm run build

npm-dev:
	@echo "$(BLUE)[npm]$(RESET) Iniciando servidor de desenvolvimento Vite..."
	$(DOCKER_COMPOSE_EXEC) npm run dev -- --host

# Comandos de configuração Laravel
.PHONY: key-generate storage-link permissions
key-generate:
	@echo "$(BLUE)[laravel]$(RESET) Gerando chave da aplicação..."
	$(DOCKER_COMPOSE_EXEC) php artisan key:generate

storage-link:
	@echo "$(BLUE)[laravel]$(RESET) Criando link simbólico do storage..."
	$(DOCKER_COMPOSE_EXEC) php artisan storage:link

permissions:
	@echo "$(BLUE)[permissions]$(RESET) Ajustando permissões..."
	$(DOCKER_COMPOSE_EXEC) sh -c 'mkdir -p storage/framework/{cache,sessions,views,testing,cache/data} bootstrap/cache; chown -R laravel:laravel storage bootstrap/cache || chown -R www-data:www-data storage bootstrap/cache || true; find storage -type d -exec chmod 775 {} \; ; find storage -type f -exec chmod 664 {} \; ; chmod -R ug+rwX bootstrap/cache'

# Comandos de teste
.PHONY: test
test:
	@echo "$(BLUE)[test]$(RESET) Executando testes..."
	$(DOCKER_COMPOSE_EXEC) php vendor/bin/pest --colors=always

# Comandos de inicialização
.PHONY: env-init prune
env-init:
	@test -f $(ENV_FILE) || cp .env.example $(ENV_FILE)
	@echo "$(GREEN)Arquivo .env criado! Ajuste as configurações para Docker:$(RESET)"
	@echo "  - DB_HOST=db"
	@echo "  - REDIS_HOST=redis"
	@echo "  - MAIL_HOST=mailpit"
	@echo "  - APP_URL=http://localhost (para dev)"

prune:
	@echo "$(YELLOW)[prune]$(RESET) Removendo tudo (containers, volumes, imagens)..."
	$(DOCKER_COMPOSE) down --rmi all -v --remove-orphans

# Comandos SSL/HTTPS para produção (pandy.pro)
.PHONY: ssl-init ssl-status ssl-renew
ssl-init:
	@if [ -z "$(CERTBOT_EMAIL)" ]; then \
		echo "$(RED)Erro: CERTBOT_EMAIL não definido!$(RESET)"; \
		echo "$(RED)Uso: export CERTBOT_EMAIL=admin@pandy.pro && make ssl-init$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)[ssl]$(RESET) Solicitando certificado SSL para pandy.pro..."
	@echo "$(BLUE)[ssl]$(RESET) Email: $(CERTBOT_EMAIL)"
	@$(PROD_COMPOSE) run --rm --entrypoint="" certbot certbot certonly --webroot -w /var/www/certbot -d pandy.pro --email $(CERTBOT_EMAIL) --agree-tos --no-eff-email --non-interactive
	@echo "$(GREEN)[ssl]$(RESET) Certificado emitido! Recarregue o nginx: make nginx-reload"

ssl-status:
	@echo "$(BLUE)[ssl]$(RESET) Status dos certificados:"
	@$(PROD_COMPOSE) run --rm --entrypoint certbot certbot certificates || echo "$(YELLOW)Nenhum certificado encontrado$(RESET)"

ssl-renew:
	@echo "$(BLUE)[ssl]$(RESET) Renovando certificados..."
	@$(PROD_COMPOSE) run --rm --entrypoint certbot certbot renew --webroot -w /var/www/certbot --non-interactive --agree-tos || true
	@$(MAKE) nginx-reload


# Comando nginx reload
.PHONY: nginx-reload
nginx-reload:
	@echo "$(BLUE)[nginx]$(RESET) Recarregando configuração para pandy.pro..."
	@$(PROD_COMPOSE) exec nginx sh -c '
	  rm -f /etc/nginx/conf.d/default.conf;
	  if [ -f "/etc/letsencrypt/live/pandy.pro/fullchain.pem" ]; then
	    cp /etc/nginx/conf.d/pandy-https.conf /etc/nginx/conf.d/active.conf;
	    echo "$(GREEN)[nginx] Usando configuração HTTPS$(RESET)";
	  else
	    cp /etc/nginx/conf.d/pandy-http.conf /etc/nginx/conf.d/active.conf;
	    echo "$(YELLOW)[nginx] Usando configuração HTTP$(RESET)";
	  fi;
	  nginx -t && nginx -s reload;
	' || (echo "$(RED)[nginx] Falha no reload - reiniciando container...$(RESET)" && $(PROD_COMPOSE) restart nginx)

# Comandos de produção
.PHONY: deploy deploy-prod
deploy-prod:
	@echo "$(BLUE)[deploy]$(RESET) Deploy para produção (pandy.pro)..."
	@$(PROD_COMPOSE) pull || true
	@$(PROD_COMPOSE) up -d --build
	@echo "$(GREEN)[deploy]$(RESET) Deploy concluído!"

deploy: deploy-prod

# Atalhos úteis
.PHONY: dev-quickstart prod-status
dev-quickstart:
	@echo "$(GREEN)🚀 Iniciando ambiente de desenvolvimento...$(RESET)"
	@$(MAKE) env-init
	@$(MAKE) build
	@$(MAKE) up
	@$(MAKE) permissions
	@$(MAKE) key-generate || true
	@$(MAKE) storage-link || true
	@$(MAKE) npm-install || true
	@echo "$(GREEN)✅ Ambiente pronto! Acesse http://localhost$(RESET)"

prod-status:
	@echo "$(BLUE)[prod]$(RESET) Status dos containers de produção:"
	@$(PROD_COMPOSE) ps

# Help melhorado
.PHONY: help
help:
	@echo "$(GREEN)📚 MagicAI - Comandos Makefile$(RESET)"
	@echo ""
	@echo "$(BLUE)🔨 Comandos básicos:$(RESET)"
	@echo "  env-init                 - Cria arquivo .env a partir do exemplo"
	@echo "  build [MODE=dev|prod]    - Constrói imagens Docker"
	@echo "  up [MODE=dev|prod]       - Sobe containers"
	@echo "  down [MODE=dev|prod]     - Para containers"
	@echo "  restart [MODE=dev|prod]  - Reinicia containers"
	@echo ""
	@echo "$(BLUE)🐘 Comandos Laravel:$(RESET)"
	@echo "  artisan cmd='...'        - Executa comando Artisan"
	@echo "  migrate                  - Executa migrações"
	@echo "  seed                     - Popula banco"
	@echo "  key-generate             - Gera APP_KEY"
	@echo "  permissions              - Ajusta permissões"
	@echo ""
	@echo "$(BLUE)📦 Dependências:$(RESET)"
	@echo "  composer-install         - Instala dependências PHP"
	@echo "  npm-install              - Instala dependências JS"
	@echo "  npm-dev                  - Servidor Vite (dev)"
	@echo "  npm-build                - Compila assets"
	@echo ""
	@echo "$(BLUE)🔒 SSL/HTTPS (pandy.pro):$(RESET)"
	@echo "  ssl-init                 - Emite certificado (precisa CERTBOT_EMAIL)"
	@echo "  ssl-status               - Status dos certificados"
	@echo "  ssl-renew                - Renova certificados"
	@echo "  nginx-reload             - Recarrega Nginx"
	@echo ""
	@echo "$(BLUE)🚀 Produção:$(RESET)"
	@echo "  deploy-prod              - Deploy para pandy.pro"
	@echo "  prod-status              - Status produção"
	@echo ""
	@echo "$(BLUE)⚡ Atalhos:$(RESET)"
	@echo "  dev-quickstart           - Setup completo desenvolvimento"
	@echo "  test                     - Executa testes Pest"
	@echo "  prune                    - Remove tudo Docker"
	@echo ""
	@echo "$(YELLOW)💡 Exemplo SSL:$(RESET)"
	@echo "  export CERTBOT_EMAIL=admin@pandy.pro"
	@echo "  make ssl-init"


# Comando padrão
.DEFAULT_GOAL := help