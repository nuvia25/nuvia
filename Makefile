# Definição de variáveis
ENV_FILE := .env
COMPOSE_BIN ?= docker compose
MODE ?= dev
COMPOSE_FILE := docker-compose.$(MODE).yml
DOCKER_COMPOSE := $(COMPOSE_BIN) --env-file $(ENV_FILE) -f $(COMPOSE_FILE)
DOCKER_COMPOSE_EXEC := $(DOCKER_COMPOSE) exec app
PROD_COMPOSE := $(COMPOSE_BIN) -f docker-compose.prod.yml

# Carregar variáveis do .env se o arquivo existir
ifneq (,$(wildcard $(ENV_FILE)))
include $(ENV_FILE)
export
endif


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

# Comandos SSL/HTTPS para produção (genéricos com Cloudflare DNS)
.PHONY: ssl-init ssl-status ssl-renew ssl-test ssl-backup ssl-clean

ssl-init:
	@if [ -z "$(CERTBOT_EMAIL)" ] || [ -z "$(DOMAIN_NAME)" ] || [ -z "$(CLOUDFLARE_TOKEN)" ]; then \
		echo "$(RED)Erro: CERTBOT_EMAIL, DOMAIN_NAME e CLOUDFLARE_TOKEN são necessários$(RESET)"; exit 1; fi
	@echo "$(BLUE)[ssl]$(RESET) Solicitando certificado wildcard para *.$(DOMAIN_NAME) via Cloudflare DNS..."
	@$(PROD_COMPOSE) run --rm -e CLOUDFLARE_TOKEN="$(CLOUDFLARE_TOKEN)" -e DOMAIN_NAME="$(DOMAIN_NAME)" -e CERTBOT_EMAIL="$(CERTBOT_EMAIL)" certbot sh -lc "\
	  set -e; \
	  echo \"dns_cloudflare_api_token=$$CLOUDFLARE_TOKEN\" > /etc/letsencrypt/cloudflare.ini; \
	  chmod 600 /etc/letsencrypt/cloudflare.ini; \
	  certbot certonly \\ \
	    --dns-cloudflare \\ \
	    --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \\ \
	    -d $$DOMAIN_NAME -d *.$$DOMAIN_NAME \\ \
	    --email $$CERTBOT_EMAIL --agree-tos --no-eff-email --non-interactive; \
	"
	@echo "$(GREEN)[ssl]$(RESET) Certificado emitido! Recarregando Nginx..."
	@$(MAKE) nginx-reload

ssl-status:
	@echo "$(BLUE)[ssl]$(RESET) Status dos certificados:"
	@$(PROD_COMPOSE) run --rm --entrypoint certbot certbot certificates || echo "$(YELLOW)Nenhum certificado encontrado$(RESET)"

ssl-renew:
	@echo "$(BLUE)[ssl]$(RESET) Renovando certificados (Cloudflare DNS)..."
	@$(PROD_COMPOSE) run --rm certbot sh -lc "\
	  set -e;\
	  if [ -f /etc/letsencrypt/cloudflare.ini ]; then chmod 600 /etc/letsencrypt/cloudflare.ini; fi;\
	  certbot renew --dns-cloudflare --non-interactive --agree-tos || true;\
	"
	@$(MAKE) nginx-reload

ssl-test:
	@echo "$(BLUE)[ssl]$(RESET) Teste de renovação (dry-run)..."
	@$(PROD_COMPOSE) run --rm certbot sh -lc "\
	  certbot renew --dry-run --dns-cloudflare --agree-tos || true;\
	"

ssl-backup:
	@echo "$(BLUE)[ssl]$(RESET) Backup de certificados em ./documents/letsencrypt-backup.tar.gz"
	@mkdir -p documents
	@$(PROD_COMPOSE) run --rm -v $(PWD)/documents:/backup certbot sh -lc "\
	  tar czf /backup/letsencrypt-backup.tar.gz -C / etc/letsencrypt\
	"
	@echo "$(GREEN)[ssl]$(RESET) Backup concluído!"

ssl-clean:
	@echo "$(YELLOW)[ssl]$(RESET) Limpando certificados..."
	@$(PROD_COMPOSE) down
	@$(COMPOSE_BIN) volume rm -f nuvia_certbot_conf || true
	@$(COMPOSE_BIN) volume rm -f certbot_conf || true
	@$(COMPOSE_BIN) volume rm -f letsencrypt || true
	@echo "$(GREEN)[ssl]$(RESET) Limpeza concluída."

# Comando nginx reload
.PHONY: nginx-reload
nginx-reload:
	@echo "$(BLUE)[nginx]$(RESET) Recarregando configuração de Nginx..."
	@$(PROD_COMPOSE) exec nginx sh -lc 'nginx -t && nginx -s reload' || (echo "$(RED)[nginx] Falha no reload - reiniciando container...$(RESET)" && $(PROD_COMPOSE) restart nginx)

# Comandos de produção
.PHONY: build-prod up-prod down-prod deploy deploy-prod
build-prod:
	@echo "$(BLUE)[prod]$(RESET) Build de imagens de produção..."
	@$(PROD_COMPOSE) build

up-prod:
	@echo "$(BLUE)[prod]$(RESET) Subindo serviços de produção..."
	@$(PROD_COMPOSE) up -d

down-prod:
	@echo "$(BLUE)[prod]$(RESET) Parando serviços de produção..."
	@$(PROD_COMPOSE) down

deploy-prod:
	@echo "$(BLUE)[deploy]$(RESET) Deploy para produção..."
	@$(PROD_COMPOSE) pull || true
	@$(PROD_COMPOSE) up -d --build
	@# Ativa HTTPS automaticamente se já existir certificado
	@if $(PROD_COMPOSE) run --rm --entrypoint certbot certbot certificates 2>/dev/null | grep -q "Domains: $(DOMAIN_NAME)"; then \
		echo "$(GREEN)[deploy] 🔒 Certificado encontrado - ativando HTTPS$(RESET)"; \
		$(MAKE) ssl-on; \
	else \
		echo "$(YELLOW)[deploy] 🌐 Sem certificado - permanecendo em HTTP. Rode: make ssl-init$(RESET)"; \
	fi

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
	@echo "$(BLUE)🔒 SSL/HTTPS (prod):$(RESET)"
	@echo "  ssl-init                 - Emite wildcard via Cloudflare (usa CERTBOT_EMAIL, DOMAIN_NAME, CLOUDFLARE_TOKEN)"
	@echo "  ssl-on                   - Ativa HTTPS (sed em Nginx)"
	@echo "  ssl-off                  - Desativa HTTPS (HTTP only)"
	@echo "  ssl-status               - Status dos certificados"
	@echo "  ssl-renew                - Renova certificados"
	@echo "  ssl-test                 - Dry-run de renovação"
	@echo "  ssl-backup               - Cria backup dos certificados"
	@echo "  ssl-clean                - Limpa certificados/volumes"
	@echo "  nginx-reload             - Recarrega Nginx"
	@echo ""
	@echo "$(BLUE)🚀 Produção:$(RESET)"
	@echo "  build-prod               - Build de imagens prod"
	@echo "  up-prod                  - Sobe serviços prod"
	@echo "  down-prod                - Para serviços prod"
	@echo "  deploy-prod              - Deploy completo com auto-SSL"
	@echo "  prod-status              - Status produção"
	@echo ""
	@echo "$(BLUE)⚡ Atalhos:$(RESET)"
	@echo "  dev-quickstart           - Setup completo desenvolvimento"
	@echo "  test                     - Executa testes Pest"
	@echo "  prune                    - Remove tudo Docker"
	@echo ""
	@echo "$(YELLOW)💡 Exemplo SSL:$(RESET)"
	@echo "  export DOMAIN_NAME=example.com CERTBOT_EMAIL=admin@example.com CLOUDFLARE_TOKEN=***"
	@echo "  make ssl-init"


# Comando padrão
.DEFAULT_GOAL := help