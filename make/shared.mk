##@ Shared Infrastructure (Traefik / dnsmasq)

.PHONY: shared-logs
shared-logs: ## Tail logs from the shared infrastructure, or one service using 'make shared-logs svc=traefik'.
	$(SHARED_COMPOSE) logs -f $(svc)

.PHONY: shared-ps
shared-ps: ## Show status of the shared infrastructure containers.
	$(SHARED_COMPOSE) ps

.PHONY: shared-restart
shared-restart: ## Restart the shared infrastructure.
	@$(MAKE) shared-stop
	@$(MAKE) shared-start

.PHONY: shared-start
shared-start: ## Start the shared infrastructure, reused by every project on this machine.
	$(SHARED_COMPOSE) up --detach --remove-orphans

.PHONY: shared-stop
shared-stop: ## Stop the shared infrastructure. Every project becomes unreachable until it is started again.
	$(SHARED_COMPOSE) down --remove-orphans
