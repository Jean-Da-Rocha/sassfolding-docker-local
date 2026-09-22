##@ Installation & DNS

NM_CONNECTION_NAME := $(DNS_DOMAIN)-dns
NM_INTERFACE_NAME := $(DNS_DOMAIN)0
RESOLVED_DROP_IN := /etc/systemd/resolved.conf.d/$(DNS_DOMAIN).conf
MACOS_RESOLVER_FILE := /etc/resolver/$(DNS_DOMAIN)

.PHONY: install
install: ## Install dependencies and set up the local and testing environments.
	@$(MAKE) restore-dns
	@$(MAKE) setup-local-environment
	@$(MAKE) setup-testing-environment
	@$(MAKE) configure-husky-hooks
	@$(MAKE) update-certificates
	@$(MAKE) build-clean
	@$(HYBRIDLY_RUNNER) composer install --prefer-dist --no-interaction --no-progress
	@$(HYBRIDLY_RUNNER) pnpm install --frozen-lockfile --force
	@echo "$(CYAN)[INFO]: Generating APP_KEY for local and testing environments...$(RESET)"
	@$(HYBRIDLY_RUNNER) php artisan key:generate
	@$(HYBRIDLY_RUNNER) php artisan key:generate --env=testing
	@$(MAKE) setup-dns
	@$(MAKE) restart

.PHONY: setup-dns
setup-dns: ## Set up the DNS resolver so that *.test resolves to the dnsmasq container.
ifeq ($(UNIX_SHELL_NAME),Darwin)
	@if [ -f $(MACOS_RESOLVER_FILE) ]; then \
		echo "$(YELLOW)[WARNING]: DNS resolver for *.$(DNS_DOMAIN) already exists. Skipping...$(RESET)"; \
	else \
		sudo mkdir -p /etc/resolver; \
		echo "nameserver $(DNSMASQ_IP_ADDRESS)" | sudo tee $(MACOS_RESOLVER_FILE) > /dev/null; \
		echo "$(GREEN)[SUCCESS]: macOS DNS resolver added for *.$(DNS_DOMAIN)$(RESET)"; \
	fi
else ifeq ($(UNIX_SHELL_NAME),Linux)
	@if command -v nmcli > /dev/null 2>&1 && systemctl is-active --quiet NetworkManager; then \
		$(MAKE) setup-dns-networkmanager; \
	else \
		$(MAKE) setup-dns-resolved; \
	fi
else
	@echo "$(RED)[ERROR]: Unsupported OS '$(UNIX_SHELL_NAME)'. DNS setup aborted.$(RESET)"
	@exit 1
endif

# The dummy interface needs a regular private address: systemd-resolved treats a link carrying
# only a link-local address as irrelevant and gives it no DNS scope, so the routing domain below
# would never be used.
.PHONY: setup-dns-networkmanager
setup-dns-networkmanager: ## Route *.test to dnsmasq through a dedicated NetworkManager profile.
	@echo "$(CYAN)[INFO]: Setting up DNS for *.$(DNS_DOMAIN) through NetworkManager...$(RESET)"
	@if nmcli --get-values NAME connection show | grep -qx "$(NM_CONNECTION_NAME)"; then \
		echo "$(YELLOW)[WARNING]: NetworkManager profile '$(NM_CONNECTION_NAME)' already exists. Skipping...$(RESET)"; \
	else \
		sudo nmcli connection add type dummy \
			ifname $(NM_INTERFACE_NAME) \
			con-name $(NM_CONNECTION_NAME) \
			connection.autoconnect yes \
			ipv4.method manual \
			ipv4.addresses 10.53.53.1/32 \
			ipv4.dns $(DNSMASQ_IP_ADDRESS) \
			ipv4.dns-search '~$(DNS_DOMAIN)' \
			ipv4.never-default yes \
			ipv6.method disabled > /dev/null; \
		sudo nmcli connection up $(NM_CONNECTION_NAME) > /dev/null; \
		echo "$(GREEN)[SUCCESS]: NetworkManager profile '$(NM_CONNECTION_NAME)' created for *.$(DNS_DOMAIN)$(RESET)"; \
	fi

.PHONY: setup-dns-resolved
setup-dns-resolved: ## Route *.test to dnsmasq through a systemd-resolved drop-in.
	@echo "$(CYAN)[INFO]: Setting up DNS for *.$(DNS_DOMAIN) through systemd-resolved...$(RESET)"
	@if grep -rlsE '^\s*Domains\s*=.*~\.' /etc/systemd/resolved.conf /etc/systemd/resolved.conf.d 2>/dev/null \
		| grep -qv '$(RESOLVED_DROP_IN)'; then \
		echo "$(YELLOW)[WARNING]: Another file already declares a global DNS route (Domains=~.).$(RESET)"; \
		echo "$(YELLOW)           systemd-resolved does not bind a server to a domain inside the$(RESET)"; \
		echo "$(YELLOW)           global scope, so *.$(DNS_DOMAIN) queries may reach that resolver$(RESET)"; \
		echo "$(YELLOW)           instead of dnsmasq. Install NetworkManager, or see the README$(RESET)"; \
		echo "$(YELLOW)           section 'Conflicting global DNS configuration'.$(RESET)"; \
	fi
	@sudo mkdir -p /etc/systemd/resolved.conf.d
	@printf '[Resolve]\nDNS=%s\nDomains=~%s\n' "$(DNSMASQ_IP_ADDRESS)" "$(DNS_DOMAIN)" \
		| sudo tee $(RESOLVED_DROP_IN) > /dev/null
	@if systemctl is-active --quiet systemd-resolved; then \
		sudo systemctl restart systemd-resolved; \
		echo "$(GREEN)[SUCCESS]: systemd-resolved DNS config added for *.$(DNS_DOMAIN)$(RESET)"; \
	else \
		echo "$(YELLOW)[WARNING]: systemd-resolved is not running. Please start it manually.$(RESET)"; \
	fi

.PHONY: restore-dns
restore-dns: ## Restore the default DNS settings.
	@echo "$(CYAN)[INFO]: Restoring default DNS...$(RESET)"
ifeq ($(UNIX_SHELL_NAME),Darwin)
	@if [ -f $(MACOS_RESOLVER_FILE) ]; then \
		sudo rm -f $(MACOS_RESOLVER_FILE); \
		echo "$(GREEN)[SUCCESS]: Removed macOS DNS resolver for *.$(DNS_DOMAIN).$(RESET)"; \
	else \
		echo "$(YELLOW)[WARNING]: No macOS DNS resolver for *.$(DNS_DOMAIN) to remove.$(RESET)"; \
	fi
else ifeq ($(UNIX_SHELL_NAME),Linux)
	@if command -v nmcli > /dev/null 2>&1 && nmcli --get-values NAME connection show | grep -qx "$(NM_CONNECTION_NAME)"; then \
		sudo nmcli connection delete $(NM_CONNECTION_NAME) > /dev/null; \
		echo "$(GREEN)[SUCCESS]: Removed NetworkManager profile '$(NM_CONNECTION_NAME)'.$(RESET)"; \
	fi
	@if [ -f $(RESOLVED_DROP_IN) ]; then \
		sudo rm -f $(RESOLVED_DROP_IN); \
		sudo systemctl restart systemd-resolved 2>/dev/null || true; \
		echo "$(GREEN)[SUCCESS]: Removed systemd-resolved config for *.$(DNS_DOMAIN).$(RESET)"; \
	fi
else
	@echo "$(RED)[ERROR]: Unsupported OS '$(UNIX_SHELL_NAME)'. DNS setup aborted.$(RESET)"
	@exit 1
endif
