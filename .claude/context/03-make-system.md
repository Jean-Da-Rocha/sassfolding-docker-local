# 03 - The make system

## Chain

The application's `Makefile` exports three variables and includes `make/main.mk`, which includes
everything else. That Makefile is also where a project overrides a variable, declared **before**
the include line, since every variable in `infra.mk` uses `?=`.

## main.mk

Derives the project name from the directory, slugifies it, allows an override, and detects the
operating system. Defines the execution aliases:

| Alias | Meaning |
|-------|---------|
| `HYBRIDLY_EXEC` | `compose exec -it hybridly`, assumes the container is up |
| `HYBRIDLY_RUNNER` | `compose run --rm --no-deps hybridly`, used during installation |
| `SHARED_COMPOSE` | `compose` against the shared stack under its own project name |

The `help` target parses `##` and `##@` markers across every make file and prints them grouped.

## infra.mk

`.EXPORT_ALL_VARIABLES:` at the top, so every variable reaches the environment and is available
for compose substitution. It holds the DNS settings, the shared project and network names, the
identity used inside the image, the published ports and every version.

The ports for HTTP and HTTPS belong to the shared Traefik and never collide. The three published
per project (database, cache, Vite) are the ones to override when running two projects at once.

## Targets by file

**docker.mk**: `start` (which depends on `shared-start`), `stop`, `reset`, `restart`, `build`,
`build-clean`, `rebuild`, `rebuild-clean`, `destroy`, `purge`, `logs`, `ps`, `shell`.

There is no double-negative flag any more. `stop` always keeps the data, `reset` always deletes
it, `build-clean` always ignores the cache. `rebuild` no longer touches DNS: the resolver points
at a fixed address and no longer depends on the container lifecycle.

**shared.mk**: `shared-start`, `shared-stop`, `shared-restart`, `shared-ps`, `shared-logs`.

**backend.mk**: the Laravel and Composer passthroughs, plus `seed`, which builds the fully
qualified seeder class name and fails with a clear message when an argument is missing.

**frontend.mk**: ESLint, the pnpm passthrough, the four taze variants, Vitest and vue-tsc. They
all use `pnpm exec`, since pnpm 12 dropped the `--no-install` flag and `pnpm exec` avoids
fetching a package that is already installed.

**environment.mk**: generates the env files with `envsubst` and rewrites the container name inside
the Husky hooks. **These targets overwrite existing env files.**

**certs.mk**: installs the mkcert CA if needed, generates a wildcard certificate for the project
and for the shared stack, regenerates the dynamic file listing every certificate for Traefik, and
copies the root CA into the image build context.

**install.mk**: the full installation sequence, and the DNS targets.

## Adding a target

Pick the right file, declare `.PHONY`, document it with a `##` comment so it shows up in the help,
use `$(HYBRIDLY_EXEC)` for anything running inside the application container, and validate
required arguments with `ifndef` and `$(error ...)`.
