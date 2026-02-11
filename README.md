# Sassfolding Docker

## Table of contents

- [Introduction](#introduction)
- [Features](#features)
- [Architecture](#architecture)
- [Usage](#usage)
- [Make Commands](#make-commands)
- [Advanced Topics](#advanced-topics)


## Introduction

> [!WARNING]
> This Docker setup has only been tested on the following operating systems:
> - **ZorinOS 17**
> - **Ubuntu 24.2**
> - **Sequoia 15.5**
>
> It is for **local development only** and is not meant to be used in **production**.
> Also, it only supports **macOS** and **Linux** based operating systems.

This project provides a standardized and modular Docker-based development environment tailored for Laravel +
Hybridly applications. It includes SSL support for local domains, isolated container and volume naming per
project, and a wide array of pre-configured services to boost development productivity out of the box.

> [!NOTE]
> This setup is not compatible with Laravel Sail as it follows a fundamentally different philosophy and architecture

## Features

- Fully configurable via Makefile variables (versions, ports, project name, TLD, etc.)
- Unique container, volume, and network names per project (COMPOSE_PROJECT_NAME)
- Configurable TLD for local domains (default: `.test`, customizable via `DNS_DOMAIN`)
- Built-in SSL certificates via mkcert
- FrankenPHP + Laravel Octane for high-performance PHP serving
- Multi-stage Dockerfile (dev and prod targets)
- Mail and object storage (Mailpit, RustFS) included

## Architecture

| Container       | Purpose                                                     |
|-----------------|-------------------------------------------------------------|
| **dnsmasq**     | Lightweight DNS server for wildcard local domain resolution |
| **Hybridly**    | FrankenPHP + Octane + Node.js (PHP server + Vite dev)       |
| **Mailpit**     | Local SMTP server and email inbox for testing emails        |
| **MySQL**       | Relational database for both local development and testing  |
| **Redis**       | Used for queues, cache, and sessions                        |
| **RustFS**      | S3-compatible object storage (for local file upload testing)|
| **RustFS-init** | Init container for automatic bucket creation (exits after)  |
| **Traefik**     | Dynamic reverse proxy with TLS termination and dashboard    |

### Request Flow

```
Browser -> Traefik (TLS on :443) -> FrankenPHP/Octane (:8000) -> Laravel
```

## Usage

This setup is supposed to be paired with the [Sassfolding](https://github.com/Jean-Da-Rocha/sassfolding) scaffold.

After cloning or downloading this repository, export the **DOCKER_DIRECTORY** variable in your **.bashrc**, **.zshrc**,
or any shell configuration file you use so that the Sassfolding project can easily point to the Docker setup

For example, in a **.zshrc** file:

```shell
export DOCKER_DIRECTORY="$HOME/sassfolding-docker-local"
```

The whole docker project is based on the
[COMPOSE_PROJECT_NAME](https://docs.docker.com/compose/how-tos/environment-variables/envvars/#compose_project_name)
variable, which is understood by Docker.

When you first pull the Sassfolding project and run the ```make install``` command, the script will use the
slugified version of your working directory. For example, with a working directory named **sassfolding**:

- Container names: sassfolding-redis, sassfolding-hybridly, sassfolding-traefik, etc.
- Network name: project.sassfolding
- Volume names: sassfolding-redis-data, sassfolding-mail-data, etc.
- URLs: app.sassfolding.test, mail.sassfolding.test, etc.

> [!NOTE]
> If you want to use a different name than the current working directory, you can set the **OVERRIDE_PROJECT_NAME**
> variable at the top of the Makefile. Its slugified version will take priority and be used as the
> **COMPOSE_PROJECT_NAME** throughout the project.

To experiment with versions, ports, or other configurations, override these values at the top of your Makefile (in the
Sassfolding project). For example, to use a different PHP version or TLD:

```makefile
# Empty by default. Set a value if you don't want to use the working directory as project name.
OVERRIDE_PROJECT_NAME ?=

# The DOCKER_DIRECTORY variable is inherited from .bashrc, .zshrc, etc.
DOCKER_DIRECTORY ?=
PROJECT_DIRECTORY := $(CURDIR)

export DOCKER_DIRECTORY
export PROJECT_DIRECTORY
export OVERRIDE_PROJECT_NAME

# Variables to override
PHP_VERSION := 8.4
DNS_DOMAIN := test

include $(DOCKER_DIRECTORY)/make/main.mk
```

> [!NOTE]
> You can refer to the **make/infra.mk** file in this project to see the default versions and ports.

> [!TIP]
> Run the ```make rebuild``` command to reflect your changes.

## Make Commands

All commands run inside Docker containers. Run `make help` to see the full list grouped by category, or `make` on its
own (defaults to help).

### Docker Lifecycle

| Command                       | Description                                                     |
|-------------------------------|-----------------------------------------------------------------|
| `make start`                  | Start all containers in detached mode                           |
| `make stop`                   | Stop all containers                                             |
| `make stop keep-volumes=0`    | Stop all containers and remove volumes                          |
| `make restart`                | Stop and start all containers                                   |
| `make build`                  | Build all Docker images                                         |
| `make build keep-cache=0`     | Build without Docker cache                                      |
| `make rebuild`                | Stop, restore DNS, build, setup DNS, start                      |
| `make destroy`                | Tear down project: containers, volumes, and images               |
| `make purge`                  | Prune ALL unused Docker resources system-wide (with confirmation)|
| `make logs`                   | Tail logs from all containers                                   |
| `make logs svc=hybridly`      | Tail logs from a specific container                             |
| `make ps`                     | Show status of all containers                                   |
| `make shell`                  | Open a bash shell in the hybridly container                     |

### Backend (Laravel / PHP)

| Command                                        | Description                                       |
|------------------------------------------------|---------------------------------------------------|
| `make artisan cmd="..."`                       | Run any Artisan command                            |
| `make test`                                    | Run the full Pest test suite                       |
| `make test filter=UserControllerTest`          | Run tests matching a filter                        |
| `make migrate`                                 | Run database migrations                            |
| `make fresh`                                   | Drop all tables and re-run migrations              |
| `make fresh seed=1`                            | Same as above, but also seed the database          |
| `make seed module=Users class=UserSeeder`      | Run a module-scoped seeder                         |
| `make tinker`                                  | Open a Laravel Tinker session                      |
| `make cache-clear`                             | Clear all Laravel caches                           |
| `make phpstan`                                 | Run PHPStan static analysis                        |
| `make pint`                                    | Fix PHP coding style with Laravel Pint             |
| `make composer cmd="..."`                      | Run any Composer command                           |

#### Module-scoped seeders

Seeders follow the modular monolith pattern and live at `modules/{Module}/Database/Seeders/`. The `seed` target
constructs the fully qualified class name automatically:

```shell
make seed module=Users class=UserSeeder
# Resolves to: Modules\Users\Database\Seeders\UserSeeder
```

### Frontend (Node / pnpm)

| Command                        | Description                                                  |
|--------------------------------|--------------------------------------------------------------|
| `make eslint`                  | Run ESLint with auto-fix                                     |
| `make vue-tsc`                 | Run TypeScript type checking                                 |
| `make pnpm cmd="..."`         | Run any pnpm command                                         |
| `make taze`                    | Check for outdated minor dependencies                        |
| `make taze major=1`            | Check for outdated major dependencies                        |
| `make taze-write`              | Write minor updates to package.json and install              |
| `make taze-write major=1`      | Write major updates to package.json and install              |

### Installation & DNS

| Command              | Description                                               |
|----------------------|-----------------------------------------------------------|
| `make install`       | Full setup: DNS, env files, certs, build, deps, keys      |
| `make setup-dns`     | Configure OS DNS resolver for the project TLD             |
| `make restore-dns`   | Remove OS DNS resolver configuration                      |

### Environment & Certificates

| Command                          | Description                                           |
|----------------------------------|-------------------------------------------------------|
| `make setup-local-environment`   | Generate .env from .env.example                       |
| `make setup-testing-environment` | Generate .env.testing from .env.testing.example       |
| `make configure-husky-hooks`     | Bind Husky hooks to the right Docker container        |
| `make update-certificates`       | Generate SSL certificates for project domains         |

## Advanced topics

### DNS Resolution

The stack uses a **dnsmasq** container to provide wildcard DNS resolution for all `*.{project}.{tld}` domains. This
means any subdomain (existing or future) automatically resolves to `127.0.0.1` without maintaining a list of entries.

The `make setup-dns` target configures your OS to forward queries for the configured TLD to the dnsmasq container:

- **Linux**: Creates a systemd-resolved drop-in config at `/etc/systemd/resolved.conf.d/{tld}.conf`
- **macOS**: Creates a resolver file at `/etc/resolver/{tld}`

The `make restore-dns` target removes these configurations. Both targets require `sudo` (prompted once during setup).

### Custom TLD

The TLD is configurable via the `DNS_DOMAIN` variable in `make/infra.mk` (default: `test`). Override it in your
Makefile to use a different TLD:

```makefile
DNS_DOMAIN := localhost
```

This will generate URLs like `app.sassfolding.localhost`, certificates for `*.sassfolding.localhost`, etc.

> [!TIP]
> `.test` is an IETF-reserved TLD (RFC 6761) that will never conflict with real domains. Other safe choices
> are `.localhost` and `.local`.

### FrankenPHP + Laravel Octane

The hybridly container uses [FrankenPHP](https://frankenphp.dev/) as the PHP application server, powered by
[Laravel Octane](https://laravel.com/docs/octane). FrankenPHP replaces the traditional Nginx + PHP-FPM combination:

- **No FastCGI**: FrankenPHP serves PHP directly (built on Caddy)
- **Persistent workers**: Octane keeps the application in memory for faster response times
- **File watching**: The `--watch` flag in development restarts workers on PHP file changes
- **Production-ready**: The Dockerfile includes a `prod` stage with no dev tools

### Multi-stage Dockerfile

The hybridly Dockerfile has three stages:

| Stage    | Contents                                            | Used By    |
|----------|-----------------------------------------------------|------------|
| **base** | FrankenPHP + PHP extensions + Composer              | Both       |
| **dev**  | base + Xdebug + Node.js + pnpm + supervisor        | Local dev  |
| **prod** | base only (no Node, no Xdebug, no supervisor)      | Production |

### RustFS Object Storage

[RustFS](https://github.com/rustfs/rustfs) is a high-performance, S3-compatible object storage system written in Rust.
It serves as a drop-in replacement for MinIO, providing local file upload testing capabilities for Laravel applications.

#### Exposed URLs

| URL                                    | Purpose                          |
|----------------------------------------|----------------------------------|
| **storage.{project}.{tld}**           | S3 API endpoint for file access  |
| **rustfs.{project}.{tld}**            | Web console for bucket management |

#### Automatic Bucket Creation

RustFS does not natively support automatic bucket creation via environment variables. To work around this limitation,
the stack uses an **init container pattern** with the `rustfs-init` service:

1. The `rustfs` container starts and exposes the S3 API on port 9000
2. Once the healthcheck passes, `rustfs-init` starts
3. The init container uses the [Chainguard MinIO Client (mc)](https://images.chainguard.dev/directory/image/minio-client/overview)
   to create the bucket defined by `${AWS_BUCKET}` and sets public read access
4. After completing its tasks, `rustfs-init` exits automatically and does not consume resources
