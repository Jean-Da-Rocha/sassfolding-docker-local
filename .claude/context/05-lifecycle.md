# 05 - Installation and operation

Every command runs **from the application directory**, never from this repository.

## Prerequisites

Docker with compose 2.20.3 or later, required by the `include:` directive. Git, Make, mkcert, and
`DOCKER_DIRECTORY` exported from the shell profile.

## First installation

`make install` runs, in order: restore any leftover DNS configuration, generate the local and
testing env files, rewrite the Husky hooks with the right container name, generate the
certificates, build the images from scratch, install Composer and pnpm dependencies through a
throwaway container, generate the application keys, configure the OS resolver, and restart.

Two steps stay manual afterwards: running the migrations, and generating the IDE helper files.

The order matters in one place: certificates before build, because the image copies the root CA.

## Daily operation

```
make start          brings up the shared stack, then the project
make ps             project containers
make shared-ps      shared containers
make logs           follow the project logs
make shell          a shell inside the application container
make stop           stops the project, keeps the data and the shared stack
```

Stopping a project leaves Traefik and dnsmasq running for the others.

## Coming back after a pause

```
make start
make ps
make setup-dns      only if the domains stopped resolving
make migrate
```

If the build fails or the images have gone stale, `make rebuild`. If the certificates expired,
`make update-certificates` then `make rebuild`.

## Data lifecycle

| Command | Containers | Volumes | Images |
|---------|-----------|---------|--------|
| `make stop` | removed | **kept** | kept |
| `make reset` | removed | removed | kept |
| `make destroy` | removed | removed | removed |
| `make purge` | the entire machine, with a confirmation prompt | | |

Deleting the database volume is the only simple way to re-run the init script that creates the
testing database.

## Changing a version or a port

Override the variable in the application's Makefile, above the include line, then `make rebuild`.
Do not edit `infra.mk` for a project-specific need: that file is shared by every project using
this setup.

## Running two projects at once

Traefik and dnsmasq are shared, so the web ports never collide. Three ports are still published
per project, for host tooling: the database, the cache and the Vite dev server. Override those
three in the second project's Makefile. The application URLs are unaffected, they all go through
the shared proxy.

## Troubleshooting

| Symptom | Where to look |
|---------|---------------|
| A domain does not resolve | `make setup-dns`, and check the shared dnsmasq is running |
| Certificate warning in the browser | `make update-certificates` then `make rebuild` |
| Vite fails to start on a certificate read | the app name in the env file must match the project name |
| TLS error on S3 calls from PHP | the root CA is not in the image, rebuild after generating certificates |
| Git hooks failing | the containers are down, or the hook still names another container |
| The testing database is missing | the database volume was initialised without the script, reset it |
| A port is already in use | another project is running, or the host resolver holds port 53 |
| Everything feels slow | Xdebug runs on every request by default |
