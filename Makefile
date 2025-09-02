# ========== CONFIGURAÇÕES BASE ==========
include .env
export

# Detectar se é docker-compose ou docker compose
DOCKER_COMPOSE := $(shell command -v docker-compose 2> /dev/null)
ifeq ($(DOCKER_COMPOSE),)
	DOCKER_COMPOSE_CMD = docker compose
else
	DOCKER_COMPOSE_CMD = docker-compose
endif

DOCKER_PROD = $(DOCKER_COMPOSE_CMD) -f docker-compose.prod.yml
DOCKER_DEV = $(DOCKER_COMPOSE_CMD) -f docker-compose.dev.yml
DOCKER_PROD_EXEC = $(DOCKER_PROD) exec app

# ========== VERIFICAÇÃO DE DEPENDÊNCIAS ==========
check-docker:
	@echo "🔍 ### Verificando Docker ###"
	@if ! command -v docker &> /dev/null; then \
		echo "❌ Docker não encontrado. Instale Docker primeiro."; \
		exit 1; \
	fi
	@if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then \
		echo "❌ Docker Compose não encontrado. Instale Docker Compose primeiro."; \
		exit 1; \
	fi
	@echo "✅ Docker: $(shell docker --version)"
	@if command -v docker-compose &> /dev/null; then \
		echo "✅ Docker Compose: $(shell docker-compose --version)"; \
	else \
		echo "✅ Docker Compose: $(shell docker compose version)"; \
	fi

# ========== SSL WILDCARD SIMPLIFICADO (Cloudflare) ==========

# 1. Setup inicial das credenciais Cloudflare (automático)
ssl-setup: check-docker
	@echo "🔧 ### Setup inicial Cloudflare ###"
	@if [ -z "$(CLOUDFLARE_TOKEN)" ]; then echo "❌ CLOUDFLARE_TOKEN não definido no .env"; exit 1; fi
	@echo "Criando estrutura de credenciais..."
	@if [ -d "certbot" ]; then \
		echo "Removendo diretório certbot existente..."; \
		chmod -R 755 certbot 2>/dev/null || sudo chmod -R 755 certbot 2>/dev/null || true; \
		rm -rf certbot 2>/dev/null || sudo rm -rf certbot 2>/dev/null || { \
			echo "⚠️ Não foi possível remover o diretório certbot. Tentando continuar..."; \
		}; \
	fi
	@mkdir -p certbot
	@echo "# Cloudflare API Token (novo formato)" > certbot/cloudflare.ini
	@echo "dns_cloudflare_api_token = $(CLOUDFLARE_TOKEN)" >> certbot/cloudflare.ini
	@chmod 600 certbot/cloudflare.ini
	@echo "✅ Credenciais Cloudflare configuradas automaticamente!"

# 2. Configurar SSL wildcard pela primeira vez
ssl-init: check-docker
	@echo "🔒 ### Configurando SSL Wildcard ###"
	@if [ -z "$(DOMAIN_NAME)" ]; then echo "❌ DOMAIN_NAME não definido no .env"; exit 1; fi
	@if [ -z "$(CERTBOT_EMAIL)" ]; then echo "❌ CERTBOT_EMAIL não definido no .env"; exit 1; fi
	@if [ -z "$(CLOUDFLARE_TOKEN)" ]; then echo "❌ CLOUDFLARE_TOKEN não definido no .env"; exit 1; fi
	@echo "Domínio: *.$(DOMAIN_NAME) | Email: $(CERTBOT_EMAIL)"
	@$(MAKE) ssl-setup
	@echo "Gerando certificado wildcard via Cloudflare DNS..."
	docker run --rm \
		-v certbot_conf:/etc/letsencrypt \
		-v certbot_www:/var/www/certbot \
		-v $(PWD)/certbot/cloudflare.ini:/etc/letsencrypt/cloudflare.ini:ro \
		certbot/dns-cloudflare:latest \
		certonly --non-interactive \
		--agree-tos --email $(CERTBOT_EMAIL) \
		--dns-cloudflare \
		--dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
		-d $(DOMAIN_NAME) -d *.$(DOMAIN_NAME)
	@echo "✅ Certificado wildcard gerado! Ativando HTTPS..."
	@$(MAKE) ssl-on
	@echo "🎉 SSL wildcard configurado para: *.$(DOMAIN_NAME)"
	@echo "🌐 Agora funciona para qualquer subdomínio!"

# 3. Ativar/Desativar HTTPS
ssl-on: check-docker
	@echo "🔒 ### Ativando HTTPS ###"
	@docker run --rm -v certbot_conf:/certs alpine \
		test -f /certs/live/$(DOMAIN_NAME)/fullchain.pem || \
		(echo "❌ Certificado não encontrado. Execute: make ssl-init" && exit 1)
	@sed 's/#SSL_START//g; s/#SSL_END//g' \
		.docker/nginx/conf.d/default.conf > .docker/nginx/conf.d/default.conf.tmp && \
		mv .docker/nginx/conf.d/default.conf.tmp .docker/nginx/conf.d/default.conf
	$(DOCKER_PROD) restart nginx
	@echo "✅ HTTPS ativado para todos os subdomínios!"

ssl-off: check-docker
	@echo "🌐 ### Desativando HTTPS ###"
	@sed 's/^[^#]*return 301/#SSL_START&#SSL_END/g; s/^[^#]*\(server {\|listen 443\|ssl_\|http2 on\)/#SSL_START&#SSL_END/g; s/^[^#]*} #SSL_END/#SSL_START&#SSL_END/g' \
		.docker/nginx/conf.d/default.conf > .docker/nginx/conf.d/default.conf.tmp && \
		mv .docker/nginx/conf.d/default.conf.tmp .docker/nginx/conf.d/default.conf
	$(DOCKER_PROD) restart nginx
	@echo "✅ HTTPS desativado - rodando apenas HTTP"

# 4. Renovar certificados (automático via cron)
ssl-renew: check-docker
	@echo "🔄 ### Renovando certificados wildcard ###"
	@if [ -z "$(CLOUDFLARE_TOKEN)" ]; then echo "❌ CLOUDFLARE_TOKEN não definido no .env"; exit 1; fi
	@$(MAKE) ssl-setup  # Regenera credenciais com token atual
	docker run --rm \
		-v certbot_conf:/etc/letsencrypt \
		-v certbot_www:/var/www/certbot \
		-v $(PWD)/certbot/cloudflare.ini:/etc/letsencrypt/cloudflare.ini:ro \
		certbot/dns-cloudflare:latest \
		renew --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini --quiet
	$(DOCKER_PROD) restart nginx
	@echo "✅ Certificados renovados!"

# 5. Status e teste
ssl-status: check-docker
	@echo "📊 ### Status SSL ###"
	@docker run --rm -v certbot_conf:/certs alpine \
		ls -la /certs/live/ 2>/dev/null || echo "❌ Nenhum certificado encontrado"
	@docker run --rm -v certbot_conf:/etc/letsencrypt \
		certbot/dns-cloudflare:latest certificates 2>/dev/null || true

ssl-test: check-docker
	@echo "🧪 ### Testando renovação (dry-run) ###"
	@if [ -z "$(CLOUDFLARE_TOKEN)" ]; then echo "❌ CLOUDFLARE_TOKEN não definido no .env"; exit 1; fi
	@$(MAKE) ssl-setup  # Regenera credenciais
	docker run --rm \
		-v certbot_conf:/etc/letsencrypt \
		-v certbot_www:/var/www/certbot \
		-v $(PWD)/certbot/cloudflare.ini:/etc/letsencrypt/cloudflare.ini:ro \
		certbot/dns-cloudflare:latest \
		renew --dry-run --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini

ssl-backup: check-docker
	@echo "💾 ### Fazendo backup dos certificados ###"
	@backup_name="ssl_backup_$(shell date +%Y%m%d_%H%M%S).tar.gz"; \
	docker run --rm -v certbot_conf:/data -v $(PWD):/backup alpine \
		tar czf /backup/$$backup_name -C /data .; \
	echo "✅ Backup salvo como: $$backup_name"

# Limpar setup SSL (útil para recomeçar)
ssl-clean:
	@echo "🧹 ### Limpando configurações SSL ###"
	@if [ -d "certbot" ]; then \
		echo "Removendo diretório certbot..."; \
		chmod -R 755 certbot 2>/dev/null || sudo chmod -R 755 certbot 2>/dev/null || true; \
		rm -rf certbot 2>/dev/null || sudo rm -rf certbot 2>/dev/null || { \
			echo "⚠️ Não foi possível remover completamente o diretório certbot"; \
			echo "Execute manualmente: sudo rm -rf certbot"; \
		}; \
	fi
	@echo "✅ Limpeza concluída!"
	@echo "💡 Execute: make ssl-init para reconfigurar"

# ========== DEPLOY LARAVEL INTELIGENTE ==========

# Build e cache para produção
build-prod: check-docker
	@echo "🏗️ ### Construindo imagem de produção ###"
	$(DOCKER_PROD) build --no-cache app

# Deploy completo
deploy-prod: check-docker down-prod build-prod up-prod
	@echo "⏳ Aguardando containers ficarem prontos..."
	@sleep 15
	@echo "🔄 ### Executando otimizações Laravel ###"
	@echo "Instalando dependências..."
	-$(DOCKER_PROD_EXEC) composer install --no-dev --optimize-autoloader --no-interaction
	@echo "Configurando aplicação..."
	-$(DOCKER_PROD_EXEC) php artisan key:generate --force --no-interaction
	@echo "Executando migrations..."
	-$(DOCKER_PROD_EXEC) php artisan migrate --force --no-interaction
	@echo "Criando caches..."
	-$(DOCKER_PROD_EXEC) php artisan config:cache
	-$(DOCKER_PROD_EXEC) php artisan route:cache
	-$(DOCKER_PROD_EXEC) php artisan view:cache
	@echo "Configurando storage..."
	-$(DOCKER_PROD_EXEC) php artisan storage:link --force
	@echo "🗂️ ### Configurando permissões ###"
	-$(DOCKER_PROD_EXEC) chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true
	-$(DOCKER_PROD_EXEC) chmod -R 775 /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true
	@echo "✅ Otimizações Laravel concluídas!"
	@echo "🚀 ### Deploy concluído! ###"
	@if docker run --rm -v certbot_conf:/certs alpine test -f /certs/live/$(DOMAIN_NAME)/fullchain.pem 2>/dev/null; then \
		echo "🔒 Certificado wildcard encontrado - ativando HTTPS..." && $(MAKE) ssl-on; \
	else \
		echo "🌐 SSL não configurado - rodando apenas HTTP"; \
		echo "💡 Para configurar SSL wildcard: make ssl-init"; \
	fi
	@echo "✅ Aplicação Laravel disponível!"
	@echo "🌍 HTTP:  http://$(DOMAIN_NAME), http://app.$(DOMAIN_NAME), etc."
	@echo "🔒 HTTPS: https://$(DOMAIN_NAME), https://app.$(DOMAIN_NAME), etc."
	$(DOCKER_PROD) ps

# Deploy rápido (sem rebuild)
deploy-quick: check-docker
	@echo "⚡ ### Deploy rápido (sem rebuild) ###"
	$(DOCKER_PROD) up -d --force-recreate
	@sleep 10
	-$(DOCKER_PROD_EXEC) php artisan migrate --force --no-interaction
	-$(DOCKER_PROD_EXEC) php artisan config:cache
	-$(DOCKER_PROD_EXEC) php artisan route:cache
	-$(DOCKER_PROD_EXEC) php artisan view:cache
	@echo "✅ Deploy rápido concluído!"

# ========== COMANDOS BÁSICOS DOCKER ==========

# Produção
up-prod: check-docker
	@echo "🚀 ### Iniciando containers de produção ###"
	$(DOCKER_PROD) up -d

down-prod: check-docker
	@echo "🛑 ### Parando containers de produção ###"
	$(DOCKER_PROD) down

logs-prod: check-docker
	@echo "📋 ### Logs de produção ###"
	$(DOCKER_PROD) logs -f

restart-prod: check-docker
	@echo "🔄 ### Reiniciando produção ###"
	$(DOCKER_PROD) restart

# Desenvolvimento
up-dev: check-docker
	@echo "🔧 ### Iniciando containers de desenvolvimento ###"
	$(DOCKER_DEV) up -d

down-dev: check-docker
	@echo "🛑 ### Parando containers de desenvolvimento ###"
	$(DOCKER_DEV) down

logs-dev: check-docker
	@echo "📋 ### Logs de desenvolvimento ###"
	$(DOCKER_DEV) logs -f

# ========== UTILITÁRIOS LARAVEL ==========

# Artisan commands
artisan: check-docker
	$(DOCKER_PROD_EXEC) php artisan $(filter-out $@,$(MAKECMDGOALS))

# Composer commands
composer: check-docker
	$(DOCKER_PROD_EXEC) composer $(filter-out $@,$(MAKECMDGOALS))

# Shell no container
shell: check-docker
	$(DOCKER_PROD_EXEC) sh

# Limpar cache Laravel
cache-clear: check-docker
	@echo "🧹 ### Limpando cache Laravel ###"
	-$(DOCKER_PROD_EXEC) php artisan cache:clear
	-$(DOCKER_PROD_EXEC) php artisan config:clear
	-$(DOCKER_PROD_EXEC) php artisan route:clear
	-$(DOCKER_PROD_EXEC) php artisan view:clear
	@echo "✅ Cache limpo!"

# Otimizar Laravel
optimize: check-docker
	@echo "⚡ ### Otimizando Laravel ###"
	-$(DOCKER_PROD_EXEC) php artisan config:cache
	-$(DOCKER_PROD_EXEC) php artisan route:cache
	-$(DOCKER_PROD_EXEC) php artisan view:cache
	-$(DOCKER_PROD_EXEC) composer dump-autoload --optimize
	@echo "✅ Otimização concluída!"

# Backup do banco
db-backup: check-docker
	@echo "💾 ### Backup do banco de dados ###"
	@backup_file="backup_$(shell date +%Y%m%d_%H%M%S).sql"; \
	$(DOCKER_PROD) exec -T db mysqldump -u $(DB_USERNAME) -p$(DB_PASSWORD) $(DB_DATABASE) > $$backup_file; \
	echo "✅ Backup salvo como: $$backup_file"

# Nginx
nginx-reload: check-docker
	@echo "🔄 ### Recarregando Nginx ###"
	$(DOCKER_PROD) exec nginx nginx -s reload
	@echo "✅ Nginx recarregado!"

nginx-test: check-docker
	@echo "🧪 ### Testando configuração Nginx ###"
	$(DOCKER_PROD) exec nginx nginx -t

# Health check
health: check-docker
	@echo "🩺 ### Verificando saúde da aplicação ###"
	@if curl -f -s http://localhost/health > /dev/null 2>&1; then \
		echo "✅ Aplicação saudável (HTTP)"; \
	else \
		echo "❌ Aplicação não responde (HTTP)"; \
	fi
	@if curl -f -s -k https://localhost/health > /dev/null 2>&1; then \
		echo "✅ Aplicação saudável (HTTPS)"; \
	else \
		echo "⚠️ HTTPS não disponível"; \
	fi

# Status completo
status: check-docker
	@echo "📊 ### Status completo do sistema ###"
	@echo "=== Containers ==="
	$(DOCKER_PROD) ps
	@echo ""
	@echo "=== SSL Status ==="
	@$(MAKE) ssl-status
	@echo ""
	@echo "=== Health Check ==="
	@$(MAKE) health

# Instalar Docker Compose (Ubuntu/Debian)
install-docker-compose:
	@echo "🔧 ### Instalando Docker Compose ###"
	@if command -v docker-compose &> /dev/null; then \
		echo "✅ Docker Compose já está instalado"; \
		docker-compose --version; \
	elif docker compose version &> /dev/null 2>&1; then \
		echo "✅ Docker Compose (plugin) já está disponível"; \
		docker compose version; \
	else \
		echo "📦 Instalando Docker Compose..."; \
		sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(shell uname -s)-$(shell uname -m)" -o /usr/local/bin/docker-compose; \
		sudo chmod +x /usr/local/bin/docker-compose; \
		echo "✅ Docker Compose instalado!"; \
		docker-compose --version; \
	fi

# Help
help:
	@echo "🆘 ### Comandos disponíveis ###"
	@echo ""
	@echo "=== Verificação ==="
	@echo "  check-docker           - Verificar Docker/Compose"
	@echo "  install-docker-compose - Instalar Docker Compose"
	@echo ""
	@echo "=== SSL ==="
	@echo "  ssl-init      - Configurar SSL wildcard pela primeira vez"
	@echo "  ssl-on        - Ativar HTTPS"
	@echo "  ssl-off       - Desativar HTTPS"
	@echo "  ssl-renew     - Renovar certificados"
	@echo "  ssl-status    - Status dos certificados"
	@echo "  ssl-test      - Teste de renovação"
	@echo "  ssl-clean     - Limpar configurações SSL"
	@echo ""
	@echo "=== Deploy ==="
	@echo "  deploy-prod   - Deploy completo (com rebuild)"
	@echo "  deploy-quick  - Deploy rápido (sem rebuild)"
	@echo ""
	@echo "=== Docker ==="
	@echo "  up-prod       - Iniciar produção"
	@echo "  down-prod     - Parar produção"
	@echo "  restart-prod  - Reiniciar produção"
	@echo "  logs-prod     - Ver logs de produção"
	@echo ""
	@echo "=== Laravel ==="
	@echo "  artisan       - Executar comando artisan"
	@echo "  composer      - Executar comando composer"
	@echo "  cache-clear   - Limpar cache Laravel"
	@echo "  optimize      - Otimizar Laravel"
	@echo "  shell         - Acessar shell do container"
	@echo ""
	@echo "=== Utilitários ==="
	@echo "  health        - Health check da aplicação"
	@echo "  status        - Status completo"
	@echo "  nginx-reload  - Recarregar Nginx"
	@echo "  db-backup     - Backup do banco"

# Evitar que make interprete argumentos como targets
%:
	@:

.PHONY: check-docker install-docker-compose ssl-setup ssl-init ssl-on ssl-off ssl-renew ssl-status ssl-test ssl-backup ssl-clean deploy-prod deploy-quick up-prod down-prod logs-prod restart-prod up-dev down-dev logs-dev artisan composer shell cache-clear optimize db-backup nginx-reload nginx-test health status help