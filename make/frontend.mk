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
taze: ## Check for outdated dependencies, minor and patch only.
	$(HYBRIDLY_EXEC) pnpm exec taze

.PHONY: taze-major
taze-major: ## Check for outdated dependencies, including major versions.
	$(HYBRIDLY_EXEC) pnpm exec taze major

.PHONY: taze-write
taze-write: ## Write minor and patch updates to package.json, then install.
	$(HYBRIDLY_EXEC) pnpm exec taze -w
	@$(MAKE) pnpm cmd="install"

.PHONY: taze-write-major
taze-write-major: ## Write updates including major versions to package.json, then install.
	$(HYBRIDLY_EXEC) pnpm exec taze major -w
	@$(MAKE) pnpm cmd="install"

.PHONY: vitest
vitest: ## Run the Vitest suite for composables and front-end logic.
	$(HYBRIDLY_EXEC) pnpm run vitest

.PHONY: vue-tsc
vue-tsc: ## Run TypeScript type checking for {.ts,.vue} files.
	$(HYBRIDLY_EXEC) pnpm run vue-tsc
