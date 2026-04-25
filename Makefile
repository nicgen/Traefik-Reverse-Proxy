# Docker Environment Management

DC = docker compose -f docker-compose.yml

.PHONY: help setup up down restart logs status clean

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup    Initialize project directories"
	@echo "  up       Start all services in detached mode"
	@echo "  down     Stop and remove all containers"
	@echo "  restart  Restart all services"
	@echo "  logs     Follow logs for all services"
	@echo "  status   Show container status"
	@echo "  clean    Remove unused data (volumes/networks)"

setup:
	@./setup.sh

up: setup
	$(DC) up -d

down:
	$(DC) down

restart: down up

logs:
	$(DC) logs -f

status:
	$(DC) ps

clean:
	$(DC) down -v --remove-orphans
