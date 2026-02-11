##@ SSL Certificates

update-certificates: ## Generate and update SSL certificates for the project.
	@echo "$(CYAN)[INFO]: Adding Certificate Authority to trust stores...$(RESET)"
	@if [ -f "$$(mkcert -CAROOT)/rootCA.pem" ]; then \
		echo "$(YELLOW)[WARNING]: Certificate Authority already added to trust stores.$(RESET)"; \
	else \
		mkcert -install; \
		echo "$(GREEN)[SUCCESS]: Certificate Authority added to trust stores.$(RESET)"; \
	fi
	@echo "$(CYAN)[INFO]: Updating SSL certificates for $(PROJECT_NAME_SLUG).$(DNS_DOMAIN)...$(RESET)"
	@mkcert \
		-cert-file $(DOCKER_DIRECTORY)/traefik/certs/$(PROJECT_NAME_SLUG).cert \
		-key-file $(DOCKER_DIRECTORY)/traefik/certs/$(PROJECT_NAME_SLUG).key \
		"*.$(PROJECT_NAME_SLUG).$(DNS_DOMAIN)" \
		"$(PROJECT_NAME_SLUG).$(DNS_DOMAIN)" \
		127.0.0.1 0.0.0.0 > /dev/null 2>&1
	@echo "$(GREEN)[SUCCESS]: SSL certificates generated.$(RESET)"
	@echo "$(CYAN)[INFO]: Copying mkcert root CA...$(RESET)"
	@cp "$$(mkcert -CAROOT)/rootCA.pem" $(DOCKER_DIRECTORY)/hybridly/ssl/rootCA.pem
	@echo "$(GREEN)[SUCCESS]: mkcert root CA copied.$(RESET)"
