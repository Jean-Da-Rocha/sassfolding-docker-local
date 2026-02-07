# Sassfolding Docker

## Table of contents

- [Introduction](#introduction)
- [Features](#features)
- [Architecture](#architecture)
- [Usage](#usage)
- [Make Commands](#make-commands)
- [Advanced Topics](#advanced-topics)
- [Known Issues](#known-issues)
- [Acknowledgment](#acknowledgment)

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
Hybridly applications. It includes SSL support for local .test domains, isolated container and volume naming per
project, and a wide array of pre-configured services to boost development productivity out of the box.

> [!NOTE]
> This setup is not compatible with Laravel Sail as it follows a fundamentally different philosophy and architecture

This stack was built from scratch by someone with no prior Docker experience. The process surfaced several technical
challenges, which are discussed in the [advanced topics](#advanced-topics) section.

## Features

- ⚙️ Fully configurable via Makefile variables (versions, ports, project name, etc.)
- 📦 Unique container, volume, and network names per project (COMPOSE_PROJECT_NAME)
- 🌐 Local domain support without modifying /etc/hosts, thanks to DNSMasq and Traefik
- 🔒 Built-in SSL certificates for .test domains
- 🚀 First-class support for Hybridly and Laravel Horizon
- 📬 Mail and object storage (Mailpit, RustFS) included
- 🛠️ Graceful integration with modern development workflows

## Architecture

| Container    | Purpose                                                                      |
|--------------|------------------------------------------------------------------------------|
| **DNSMasq**  | Handles wildcard DNS resolution for **.test** domains without **/etc/hosts** |
| **Hybridly** | Main app container running both PHP and Node.js                              |
| **Horizon**  | Supervisor for managing Laravel queues with Redis                            |
| **Mailpit**  | Local SMTP server and email inbox for testing emails                         |
| **RustFS**   | S3-compatible object storage (for local file upload testing)                 |
| **MySQL**    | Relational database used by Laravel for both local and testing               |
| **Nginx**    | Serves PHP requests via FastCGI since Traefik does not support it            |
| **Redis**    | Used for queues, cache, and sessions                                         |
| **Traefik**  | Dynamic reverse proxy with built-in TLS and dashboard support                |

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
- URL: app.sassfolding.test, horizon.sassfolding.test, mail.sassfolding.test, etc.

> [!NOTE]
> If you want to use a different name than the current working directory, you can set the **OVERRIDE_PROJECT_NAME**
> variable at the top of the Makefile. Its slugified version will take priority and be used as the
> **COMPOSE_PROJECT_NAME** throughout the project.

To experiment with versions, ports, or other configurations, override these values at the top of your Makefile (in the
Sassfolding project). For example, to use PHP 8.3 instead of the default 8.4, your Makefile would look like:

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
PHP_VERSION := 8.3

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
| `make horizon-pause`                           | Pause the Horizon queue worker                     |
| `make horizon-continue`                        | Resume a paused Horizon queue                      |
| `make horizon-start`                           | Start Horizon                                      |
| `make horizon-terminate`                       | Terminate Horizon                                  |

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
| `make volt-add component=...`  | Install a VoltUI component                                   |

### Installation & DNS

| Command              | Description                                               |
|----------------------|-----------------------------------------------------------|
| `make install`       | Full setup: DNS, env files, certs, build, deps, keys      |
| `make setup-dns`     | Configure DNS resolver for .test domains                  |
| `make restore-dns`   | Remove custom DNS configuration                           |

### Environment & Certificates

| Command                          | Description                                           |
|----------------------------------|-------------------------------------------------------|
| `make setup-local-environment`   | Generate .env from .env.example                       |
| `make setup-testing-environment` | Generate .env.testing from .env.testing.example       |
| `make configure-husky-hooks`     | Bind Husky hooks to the right Docker container        |
| `make update-certificates`       | Generate SSL certificates for .test domains           |

## Advanced topics

In order to use clean **.test** domains locally like **app.sassfolding.test**, the stack relies on a lightweight
DNS server: **DNSMasq**. This setup allows requests for any subdomain under **.test** to be resolved to **localhost**
(127.0.0.1), ensuring that the DNS queries are handled locally without manually editing your /etc/hosts file.

### How it works

- The dnsmasq container listens on **53/udp** and **53/tcp** (port 5353 for Linux) and handles requests to domains like
***.sassfolding.test**
- It is configured to resolve any **.test** domains to your localhost (127.0.0.1)
- For all other domains, it forwards requests to upstream resolvers like **8.8.8.8** and **1.1.1.1**

Here is the dnsmasq.conf used for the project:

```apacheconf
address=/test/127.0.0.1

no-hosts

server=8.8.8.8
server=8.8.4.4
server=1.1.1.1
server=1.0.0.1
```

### DNS Integration on Host Machine

To make your system aware of this custom DNS routing, the project provides two **Makefile** targets:

- **make setup-dns** - Adds a custom resolver configuration pointing **.test** to the **dnsmasq** container
- **make restore-dns** - Removes this custom DNS configuration and restores your system’s default settings

The behavior of these commands depends on your operating system and is determined by the **DNSMASQ_FORWARD_PORT**
variable, which specifies the DNS port to be used and is read by Docker within the **dnsmasq** container.

#### On macOS:

- Adds a file at **/etc/resolver/test** that directs DNS queries for .test domains to the container's IP, listening on
  port **53**, since macOS DNS resolver operates only on this port.
- Uses standard macOS DNS resolver behavior (no systemd needed).

#### On Linux:

- Creates a file at **/etc/systemd/resolved.conf.d/test.conf**
- Instructs **systemd-resolved** to forward **.test** queries to the container, using port **5353** by default, which
  avoids conflicts with the system's primary port **53**
- Restarts the **systemd-resolved** service to apply changes

> [!IMPORTANT]
> **systemd-resolved** must be active. If it's not running, the script will warn you to start it manually.

### Why not just use /etc/hosts?

Manually editing **/etc/hosts** is tedious and static. This approach:

- Allows dynamic per-project domain routing
- Avoids cluttering or conflicting with global system config
- Enables isolated and portable development environments

### RustFS Object Storage

[RustFS](https://github.com/rustfs/rustfs) is a high-performance, S3-compatible object storage system written in Rust.
It serves as a drop-in replacement for MinIO, providing local file upload testing capabilities for Laravel applications.

#### Exposed URLs

| URL                                    | Purpose                          |
|----------------------------------------|----------------------------------|
| **storage.{COMPOSE_PROJECT_NAME}.test** | S3 API endpoint for file access  |
| **rustfs.{COMPOSE_PROJECT_NAME}.test**  | Web console for bucket management |

#### Automatic Bucket Creation

RustFS does not natively support automatic bucket creation via environment variables. To work around this limitation,
the stack uses an **init container pattern** with the `rustfs-init` service:

1. The `rustfs` container starts and exposes the S3 API on port 9000
2. Once the healthcheck passes, `rustfs-init` starts
3. The init container uses the [Chainguard MinIO Client (mc)](https://images.chainguard.dev/directory/image/minio-client/overview)
   to create the bucket defined by `${AWS_BUCKET}` and sets public read access
4. After completing its tasks, `rustfs-init` exits automatically and does not consume resources

#### Accessing Files

Files stored in buckets with public read access can be accessed directly via:

```
https://storage.{COMPOSE_PROJECT_NAME}.test/{bucket}/{filename}
```

For example, with a project named **sassfolding** and a bucket named **media**:

```
https://storage.sassfolding.test/media/dummy.txt
```

## Known Issues

While the setup is functional and stable for development, several technical caveats remain:

- **Non-optimized build size**: Some containers could be optimized in terms of size and how volumes are handled
- **PHP and Node in the same container**: because Hybridly executes Artisan commands via Vite using the
  [**vite-plugin-run**](https://hybridly.dev/configuration/vite#run), PHP and Node must coexist in the same container.
  This design violates the separation of concerns

## Acknowledgment

This project was heavily inspired by the amazing work of the [WAYOFDEV](https://github.com/wayofdev) team. Their
projects provided both technical reference and architectural guidance that made this setup possible:

- [WAYOFDEV - Docker Shared Service](https://github.com/wayofdev/docker-shared-service)
- [WAYOFDEV - Laravel Starter Tpl](https://github.com/wayofdev/laravel-starter-tpl)

If you’re interested in professional-grade Laravel setups with Docker, be sure to check out their repositories.
