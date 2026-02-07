##@ Frontend (Node / pnpm)

.PHONY: eslint
eslint: ## Run ESLint with automatic fixing.
	$(HYBRIDLY_EXEC) pnpm run lint:fix

.PHONY: pnpm
pnpm: ## Run pnpm commands using the 'make pnpm cmd="..."' syntax.
ifndef cmd
	$(error Usage: make pnpm cmd="<command>")
endif
	$(HYBRIDLY_EXEC) pnpm $(cmd)

.PHONY: taze
taze: ## Check for outdated dependencies. Use 'make taze major=1' for major updates.
	$(HYBRIDLY_EXEC) pnpx taze $(if $(major),major)

.PHONY: taze-write
taze-write: ## Write dependency updates to package.json and install. Use 'make taze-write major=1' for major updates.
	$(HYBRIDLY_EXEC) pnpx taze $(if $(major),major) -w
	@$(MAKE) pnpm cmd="install"

.PHONY: volt-add
volt-add: ## Install VoltUI component using the 'make volt-add component=InputText' syntax.
	$(HYBRIDLY_EXEC) pnpx volt-vue add $(component) --outdir "./modules/Core/Components" --no-deps

.PHONY: vue-tsc
vue-tsc: ## Run TypeScript type checking for {.ts,.vue} files.
	$(HYBRIDLY_EXEC) pnpm run vue-tsc
