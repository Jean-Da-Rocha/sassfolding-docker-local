# 02 - The application image

`hybridly/Dockerfile`, three stages.

## base

FrankenPHP on PHP 8.5. Extensions `bcmath`, `gd`, `intl`, `mbstring`, `pcntl`, `pdo_mysql`, `zip`
compiled, plus `redis` through pecl. Composer installed at a pinned version. A `laravel` user
created with the host's UID and GID so the bind mount keeps sane ownership.

**This extension list must stay in step with the application's CI.**

## dev

Adds Xdebug, Node, pnpm through corepack, and supervisor. Copies the supervisor programs, the PHP
configuration and the mkcert root CA, then runs `update-ca-certificates` so the container trusts
the local TLS domains. Without that step, outgoing calls to the S3 API fail on certificate
verification.

Supervisor runs two programs side by side:

| Program | Command |
|---------|---------|
| `octane` | `php artisan octane:start --server=frankenphp --host=0.0.0.0 --port=8000 --watch` |
| `pnpm` | `pnpm run dev` |

Both log to stdout and stderr without rotation.

### Why one container

Hybridly's `vite-plugin-run` runs Artisan commands from the Vite dev server, so Vite needs the
`php` binary and the Laravel code in the same filesystem. Splitting them would require either
awkward cross-mounts or a remote call mechanism. In production the `prod` stage carries no Node at
all, because assets are built ahead of time.

## prod

A skeleton: it sets the user and the Octane command, nothing else. Before it can be used it needs
a Node build stage, `COPY` instructions for the application, a `COPY --from=build` for the
compiled assets, `composer install --no-dev --optimize-autoloader`, the Laravel cache commands,
and `--max-requests` on Octane to contain worker memory growth.

No compose service targets this stage.

## PHP configuration

Generous limits for upload testing, and Xdebug set to start on every request. That last setting is
convenient and expensive: it is the first thing to suspect when the application drags. Setting
`XDEBUG_MODE=off` in the container environment disables it without a rebuild.

## Build context

The application image builds from the repository root, so the root `.dockerignore` applies and
excludes the other services' directories, the make files and the git metadata. The other images
build from their own directory, where that file does not apply.
