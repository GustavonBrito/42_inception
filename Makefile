NAME     = inception
COMPOSE  = docker compose -f srcs/docker-compose.yml
SETUP    = sh srcs/requirements/tools/setup.sh

all: setup
	@$(COMPOSE) up -d --build

setup:
	@$(SETUP)

up: setup
	@$(COMPOSE) up -d

down:
	@$(COMPOSE) down

stop:
	@$(COMPOSE) stop

start:
	@$(COMPOSE) start

ps:
	@$(COMPOSE) ps

logs:
	@$(COMPOSE) logs --tail=50

re: down all

# removes the containers, the network and the images of this project only
clean:
	@$(COMPOSE) down --rmi all

# same as clean, plus the volumes and the data stored on the host
fclean:
	@$(COMPOSE) down --rmi all --volumes
	@$(SETUP) wipe

.PHONY: all setup up down stop start ps logs re clean fclean
