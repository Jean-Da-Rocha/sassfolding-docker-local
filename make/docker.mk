##@ Docker Lifecycle

.PHONY: build
build: ## Build the docker images for the project, optionally without cache using 'make build keep-cache=0' syntax.
	$(DOCKER_COMPOSE) build $(if $(filter 0, $(keep-cache)), --no-cache)

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
rebuild: ## Rebuild and restart docker containers for this project, optionally removing volumes and not using cache using 'make rebuild keep-cache=0 keep-volumes=0' syntax.
	@$(MAKE) stop $(if $(keep-volumes), keep-volumes=$(keep-volumes))
	@$(MAKE) restore-dns
	@$(MAKE) build $(if $(keep-cache), keep-cache=$(keep-cache))
	@$(MAKE) setup-dns
	@$(MAKE) start

.PHONY: restart
restart: ## Restart the project by stopping and starting all containers.
	@$(MAKE) stop
	@$(MAKE) start

.PHONY: shell
shell: ## Open a bash shell in the hybridly container.
	$(HYBRIDLY_EXEC) bash

.PHONY: start
start: ## Start the Docker containers for the project.
	$(DOCKER_COMPOSE) up --detach --remove-orphans

.PHONY: stop
stop: ## Stop the Docker containers for the project, optionally removing volumes using 'make stop keep-volumes=0' syntax.
	$(DOCKER_COMPOSE) down --remove-orphans $(if $(filter 0, $(keep-volumes)), --volumes)
