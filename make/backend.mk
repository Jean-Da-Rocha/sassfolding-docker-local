##@ Backend (Laravel / PHP)

.PHONY: artisan
artisan: ## Run artisan commands using 'make artisan cmd="..."' syntax.
	$(HYBRIDLY_EXEC) php artisan $(cmd)

.PHONY: cache-clear
cache-clear: ## Clear all Laravel caches (config, route, view, application).
	$(HYBRIDLY_EXEC) php artisan optimize:clear

.PHONY: composer
composer: ## Run composer commands using the 'make composer cmd="..."' syntax.
	$(HYBRIDLY_EXEC) composer $(cmd)

.PHONY: fresh
fresh: ## Drop all tables and re-run migrations. Use 'make fresh seed=1' to also seed.
	$(HYBRIDLY_EXEC) php artisan migrate:fresh $(if $(seed),--seed)

.PHONY: migrate
migrate: ## Run database migrations.
	$(HYBRIDLY_EXEC) php artisan migrate

.PHONY: phpstan
phpstan: ## Run static analysis with PHPStan.
	$(HYBRIDLY_EXEC) vendor/bin/phpstan analyze

.PHONY: pint
pint: ## Run Laravel Pint to fix coding style issues.
	$(HYBRIDLY_EXEC) vendor/bin/pint

.PHONY: seed
seed: ## Seed a module using 'make seed module=Users class=UserSeeder' syntax.
ifndef module
	$(error Usage: make seed module=<ModuleName> class=<SeederClass>)
endif
ifndef class
	$(error Usage: make seed module=$(module) class=<SeederClass>)
endif
	$(HYBRIDLY_EXEC) php artisan db:seed --class="Modules\\$(module)\\Database\\Seeders\\$(class)"

.PHONY: test
test: ## Run Pest tests, optionally filtered using 'make test filter=UserControllerTest' syntax.
	$(HYBRIDLY_EXEC) php artisan test $(if $(filter),--filter=$(filter))

.PHONY: tinker
tinker: ## Open a Laravel Tinker session.
	$(HYBRIDLY_EXEC) php artisan tinker
