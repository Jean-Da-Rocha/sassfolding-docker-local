##@ Docker Lifecycle

.PHONY: build
build: ## Build the docker images for the project.
	$(DOCKER_COMPOSE) build

.PHONY: build-clean
build-clean: ## Build the docker images from scratch, ignoring the Docker layer cache.
	$(DOCKER_COMPOSE) build --no-cache

.PHONY: destroy
destroy: ## Tear down this project: stop containers, remove volumes and images.
	$(DOCKER_COMPOSE) down --volumes --rmi all --remove-orphans

.PHONY: logs
logs: ## Tail logs from all containers, or a specific one using 'make logs svc=hybridly' syntax.
	$(DOCKER_COMPOSE) logs -f $(svc)

.PHONY: ps
ps: ## Show status of all containers.
	$(DOCKER_COMPOSE) ps

.PHONY: purge
purge: ## Prune ALL unused Docker resources system-wide (containers, images, volumes, networks).
	@echo "$(RED)[WARNING]: This will remove ALL unused Docker resources on your machine, not just this project.$(RESET)"
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	$(DOCKER) system prune --all --force --volumes

.PHONY: rebuild
rebuild: ## Rebuild the images and restart the project, keeping the data volumes.
	@$(MAKE) stop
	@$(MAKE) build
	@$(MAKE) start

.PHONY: rebuild-clean
rebuild-clean: ## Same as rebuild, but ignores the Docker cache and deletes the data volumes.
	@$(MAKE) reset
	@$(MAKE) build-clean
	@$(MAKE) start

.PHONY: reset
reset: ## Stop the containers and delete their data volumes (databases, mails, uploaded files).
	$(DOCKER_COMPOSE) down --remove-orphans --volumes

.PHONY: restart
restart: ## Restart the project by stopping and starting all containers.
	@$(MAKE) stop
	@$(MAKE) start

.PHONY: shell
shell: ## Open a bash shell in the hybridly container.
	$(HYBRIDLY_EXEC) bash

.PHONY: start
start: shared-start ## Start the Docker containers for the project.
	$(DOCKER_COMPOSE) up --detach --remove-orphans

.PHONY: stop
stop: ## Stop the Docker containers, keeping their data volumes.
	$(DOCKER_COMPOSE) down --remove-orphans
