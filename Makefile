MODE ?= dev

ifeq (,$(filter $(MODE),dev prod))
$(error Invalid MODE '$(MODE)'. Use MODE=dev or MODE=prod)
endif

ifneq ($(shell command -v docker-compose 2>/dev/null),)
  DC := docker-compose
else ifneq ($(shell docker compose version 2>/dev/null),)
  DC := docker compose
else
$(error Docker Compose not found. Install docker-compose v1 or docker compose v2)
endif

COMPOSE_FILE := docker-compose.$(MODE).yml
APP_SERVICE ?= app

ARGS := $(filter-out $@,$(MAKECMDGOALS))


up:
	@echo "Starting (MODE=$(MODE)) using $(COMPOSE_FILE)"
	@$(DC) -f $(COMPOSE_FILE) up -d

down:
	@$(DC) -f $(COMPOSE_FILE) down

build:
	@$(DC) -f $(COMPOSE_FILE) build

prune:
	@$(DC) -f $(COMPOSE_FILE) down -v --remove-orphans
	@docker system prune -f

restart:
	@$(DC) -f $(COMPOSE_FILE) restart

logs:
	@$(DC) -f $(COMPOSE_FILE) logs -f --tail=100

install-deps:
	@$(DC) -f $(COMPOSE_FILE) exec -T $(APP_SERVICE) git config --global --add safe.directory /var/www
	@$(DC) -f $(COMPOSE_FILE) exec -T $(APP_SERVICE) composer install --no-interaction

composer:
	@$(DC) -f $(COMPOSE_FILE) exec -T $(APP_SERVICE) composer $(ARGS)

artisan:
	@$(DC) -f $(COMPOSE_FILE) exec -T $(APP_SERVICE) php artisan $(ARGS)

shell:
	@$(DC) -f $(COMPOSE_FILE) exec $(APP_SERVICE) sh

permissions:
	@$(DC) -f $(COMPOSE_FILE) exec -T $(APP_SERVICE) git config --global --add safe.directory /var/www || true
	@$(DC) -f $(COMPOSE_FILE) exec -T $(APP_SERVICE) chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache /var/www/vendor 2>/dev/null || true
	@$(DC) -f $(COMPOSE_FILE) exec -T $(APP_SERVICE) chmod -R 775 /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true
	@$(DC) -f $(COMPOSE_FILE) exec -T $(APP_SERVICE) chmod -R 755 /var/www/vendor 2>/dev/null || true

deploy:
	@if [ "$(MODE)" != "prod" ]; then echo "Deploy disponível apenas com MODE=prod"; exit 1; fi
	@echo "Deploy (MODE=prod) using $(COMPOSE_FILE)"
	@$(DC) -f $(COMPOSE_FILE) build
	@$(DC) -f $(COMPOSE_FILE) up -d --remove-orphans
	make permissions
	@$(DC) -f $(COMPOSE_FILE) exec -T $(APP_SERVICE) sh -lc "composer install --no-dev --prefer-dist --no-interaction --no-progress"
	@$(DC) -f $(COMPOSE_FILE) exec -T $(APP_SERVICE) php artisan migrate --force

help:
	@echo "Makefile (MODE=$(MODE))"
	@echo "Using: $(DC) -f $(COMPOSE_FILE)"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(lastword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}' | sort
	@echo
	@echo "Examples:"
	@echo "  make up"
	@echo "  make artisan migrate"
	@echo "  MODE=prod make up"
	@echo "  MODE=prod make deploy"

# Allow passing extra arguments like: make composer install
%:
	@:

.PHONY: up down build prune install-deps restart logs composer artisan shell deploy permissions help