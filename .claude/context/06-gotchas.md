# 06 - Traps and constraints

Statements of fact. This is a local development setup and is assumed to be one.

## Structural

- Commands run from the application directory. There is no Makefile here.
- `DOCKER_DIRECTORY` must be exported, otherwise the application's compose file includes empty
  paths and fails.
- Compose 2.20.3 or later, for `include:`.
- Linux and macOS only. The DNS targets fail explicitly elsewhere.
- `infra.mk` is shared by every project using this setup. Project-specific overrides belong in
  that project's Makefile.

## Ordering that matters

- **Certificates before build.** The image copies the mkcert root CA at build time. Building first
  produces a container that does not trust the local TLS domains, so the application's calls to
  its own S3 API fail.
- The database init script that creates the testing database **only runs on the very first
  initialisation of the volume**. After that, only deleting the volume replays it.

## Shared infrastructure

- Stopping the shared stack takes **every** project offline, not just the current one.
- A single Traefik reads the Docker socket and therefore sees every container on the machine.
  Every router and service name must be suffixed with the project name, or two projects collide
  silently. This is the single easiest mistake to make when adding a service.
- Three ports remain published per project. Two projects at once means overriding them.
- `make purge` prunes the whole machine.

## Performance

- Xdebug is set to start on every request, including Vite's. First thing to check when the
  application drags.
- Octane watches PHP files, and Vite watches the rest. The application's Vite config already
  excludes the heavy directories to stay under the file watcher limit.

## Drift and leftovers

- Two images float on `latest`, the object storage and its init client. A rebuild can therefore
  change versions without notice. They are the only unpinned components.
- The database image declares an older default version in its own Dockerfile, overridden by the
  variable. Never build that image outside compose.
- The bucket is made publicly readable by the init container, while the application's env file
  declares a private policy. The compose file wins.
- The `prod` stage is a skeleton.

## Unpinned external dependencies

The build fetches the Node distribution, two pecl extensions and the Composer installer from the
network. A fully offline build is impossible, and a byte-identical rebuild over time is not
guaranteed.

## Not tracked, but present on disk

The generated certificates, the copied root CA and the Traefik certificate list. All regenerable
with `make update-certificates`. A fresh clone only has the placeholder files.

## What this repository does not do

No production. No volume backup or restore. No secret management: passwords sit in plain text in
the generated env files, which is acceptable locally and nowhere else. No queue worker or
scheduler container.
