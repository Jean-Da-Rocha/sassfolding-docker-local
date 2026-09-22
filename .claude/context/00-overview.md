# 00 - Overview

## Role

A standardised, modular Docker environment for Laravel and Hybridly applications. **Local
development only**, never production. Not compatible with Laravel Sail, which follows a different
philosophy.

Linux and macOS only: the DNS targets fail explicitly on anything else.

## Link to the application

The application repository carries two thin files that delegate everything here:

- its `Makefile` includes `$(DOCKER_DIRECTORY)/make/main.mk`
- its `docker-compose.yml` includes the per-project service files

Three variables are exported from the application's Makefile:

| Variable | Role |
|----------|------|
| `DOCKER_DIRECTORY` | Where to find the Dockerfiles and compose files |
| `PROJECT_DIRECTORY` | What gets mounted into the container, and where the env files are written |
| `OVERRIDE_PROJECT_NAME` | Forces a project name different from the directory name |

**Infrastructure changes happen here. Commands are run from the application directory.**

## One repository, several projects

Everything is prefixed with `COMPOSE_PROJECT_NAME`, derived from the application directory name
and slugified. Two projects can share this setup, each with its own containers, volumes,
certificates and network.

Traefik and dnsmasq are the exception: they are **shared**, one instance per machine under the
`localdev` project name, because a single Traefik already sees every project through the Docker
socket and dnsmasq answers the same thing for all of them.

## Layout

```
.dockerignore            Root build context exclusions
README.md
shared/                  Compose file for the shared Traefik and dnsmasq
dnsmasq/
hybridly/
  Dockerfile             Multi-stage base / dev / prod
  conf.d/                Supervisor programs for Octane and Vite
  config/php.ini
  ssl/rootCA.pem         mkcert root CA, copied in by update-certificates
make/
  main.mk                Entry point, variables, help, includes
  backend.mk             Laravel and PHP targets
  certs.mk               mkcert generation and the Traefik certificate list
  docker.mk              Container lifecycle
  environment.mk         Env file generation and Husky hooks
  frontend.mk            Node and pnpm targets
  infra.mk               Versions, ports, identity, DNS
  install.mk             Installation and OS DNS configuration
  shared.mk              Shared infrastructure lifecycle
mailpit/  mysql/  redis/  rustfs/
traefik/
  config/traefik.yml     Static configuration
  config/dynamic/        Generated certificate list, watched by Traefik
  certs/                 Per-project certificates, not tracked
```

## Decisions worth knowing

| When | What |
|------|------|
| August 2025 | Architecture reorganised, variables extracted into `infra.mk` and `main.mk` |
| January 2026 | MinIO replaced by RustFS, which went into maintenance mode with its images pulled from public registries |
| February 2026 | Nginx and PHP-FPM replaced by FrankenPHP and Octane; Horizon container dropped; `.test` hardcoded |
| September 2026 | Traefik and dnsmasq made shared, dnsmasq bound to loopback, DNS moved to a NetworkManager profile when available, make targets stripped of double-negative flags |
