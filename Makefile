# Definição de variáveis
ENV_FILE := .env
DOCKER_COMPOSE := docker compose --env-file $(ENV_FILE) -f docker-compose.dev.yml
DOCKER_COMPOSE_EXEC := $(DOCKER_COMPOSE) exec app

.PHONY: prepare
build:
	@which docker >/dev/null 2>&1 || (echo "Docker não está em execução!" && exit 1 )
	sudo rm -rf node_modules
	sudo rm -rf vendor
	$(DOCKER_COMPOSE) build --no-cache

.PHONY: up
up:
	@test -f $(ENV_FILE) || (echo "Arquivo $(ENV_FILE) não encontrado!" && exit 1)
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

.PHONY: sh
sh:
	$(DOCKER_COMPOSE) exec -it app /bin/bash

.PHONY: app_logs
app_logs:
	$(DOCKER_COMPOSE) logs -f app

.PHONY: nginx_logs
nginx_logs:
	$(DOCKER_COMPOSE) logs -f nginx

.PHONY: db_migrate
db_migrate:
	$(DOCKER_COMPOSE_EXEC) php artisan migrate

.PHONY: db_fresh
db_fresh:
	$(DOCKER_COMPOSE_EXEC) php artisan migrate:fresh

.PHONY: db_seed
db_seed:
	$(DOCKER_COMPOSE_EXEC) php artisan db:seed


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