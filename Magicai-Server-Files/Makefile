# Makefile para gerenciar o ambiente Docker com .env.local

# Definição de variáveis
ENV_FILE := .env
DOCKER_COMPOSE := docker compose --env-file $(ENV_FILE)

# Garantindo que o .env exista
$(ENV_FILE):
	@echo "Arquivo $(ENV_FILE) não encontrado!"
	@exit 1

# Verificação de dependências
.PHONY: check-dependencies
check-dependencies:
	@which docker >/dev/null 2>&1 || (echo "Docker não está instalado!" && exit 1)
	@test -f $(ENV_FILE) || (echo "Arquivo $(ENV_FILE) não encontrado!" && exit 1)

# Construir os containers
.PHONY: build
build: check-dependencies
	$(DOCKER_COMPOSE) build --no-cache

# Iniciar os containers em modo detached
.PHONY: up
up: check-dependencies
	$(DOCKER_COMPOSE) up -d

# Parar os containers
.PHONY: down
down: check-dependencies
	$(DOCKER_COMPOSE) down

# Reiniciar os containers
.PHONY: restart
restart: down up

# Mostrar logs
.PHONY: logs
logs: check-dependencies
	$(DOCKER_COMPOSE) logs -f

# Executar comandos específicos em containers
.PHONY: exec-app
exec-app: check-dependencies
	$(DOCKER_COMPOSE) exec app bash

.PHONY: exec-db
exec-db: check-dependencies
	$(DOCKER_COMPOSE) exec db bash

.PHONY: exec-nginx
exec-nginx: check-dependencies
	$(DOCKER_COMPOSE) exec nginx sh

# Comandos Laravel através do container
.PHONY: artisan
artisan: check-dependencies
	$(DOCKER_COMPOSE) exec app php artisan $(cmd)

.PHONY: migrate
migrate: check-dependencies
	$(DOCKER_COMPOSE) exec app php artisan migrate

.PHONY: migrate-fresh
migrate-fresh: check-dependencies
	$(DOCKER_COMPOSE) exec app php artisan migrate:fresh

.PHONY: seed
seed: check-dependencies
	$(DOCKER_COMPOSE) exec app php artisan db:seed

.PHONY: composer-install
composer-install: check-dependencies
	$(DOCKER_COMPOSE) exec app composer install

.PHONY: composer-update
composer-update: check-dependencies
	$(DOCKER_COMPOSE) exec app composer update

.PHONY: npm-install
npm-install: check-dependencies
	$(DOCKER_COMPOSE) exec app npm install

.PHONY: npm-build
npm-build: check-dependencies
	$(DOCKER_COMPOSE) exec app npm run build

# Status dos containers
.PHONY: ps
ps: check-dependencies
	$(DOCKER_COMPOSE) ps

# Limpeza
.PHONY: clean
clean: check-dependencies
	$(DOCKER_COMPOSE) down -v --remove-orphans

# Ajuda
.PHONY: help
help:
	@echo "Uso do Makefile:"
	@echo "  make build              - Constrói os containers"
	@echo "  make up                 - Inicia os containers em segundo plano"
	@echo "  make down               - Para os containers"
	@echo "  make restart            - Reinicia os containers"
	@echo "  make logs               - Exibe logs dos containers"
	@echo "  make exec-app           - Acessa o bash do container da aplicação"
	@echo "  make exec-db            - Acessa o bash do container do banco de dados"
	@echo "  make exec-nginx         - Acessa o shell do container Nginx"
	@echo "  make artisan cmd=...    - Executa comando Artisan (ex: make artisan cmd='migrate')"
	@echo "  make migrate            - Executa as migrações"
	@echo "  make migrate-fresh      - Recria e executa as migrações"
	@echo "  make seed               - Executa os seeders"
	@echo "  make composer-install   - Instala dependências do Composer"
	@echo "  make composer-update    - Atualiza dependências do Composer"
	@echo "  make npm-install        - Instala dependências do NPM"
	@echo "  make npm-build          - Compila assets"
	@echo "  make ps                 - Exibe status dos containers"
	@echo "  make clean              - Remove todos os containers e volumes"
	@echo "  make help               - Exibe esta ajuda"

# Comando padrão
.DEFAULT_GOAL := help