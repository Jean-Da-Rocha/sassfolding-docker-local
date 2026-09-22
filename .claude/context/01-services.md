# 01 - Services

One directory per service, one compose file per directory. The application's compose file
aggregates the per-project ones through `include:`. `shared/docker-compose.yml` aggregates the
shared ones.

## Shared, one per machine

| Service | Container | Image | Exposed as |
|---------|-----------|-------|-----------|
| traefik | `localdev-traefik` | `traefik:v3.7.13` | ports 80 and 443, `traefik.localdev.test` |
| dnsmasq | `localdev-dnsmasq` | `dockurr/dnsmasq:2.93` | `127.0.0.1:53` only, UDP and TCP |

They sit on an external `localdev` network that every project joins, and both restart unless
stopped.

**Traefik** mounts the Docker socket read only, its static config, the generated dynamic
directory and the certificate directory. Its dashboard is served through a regular router bound to
`api@internal` rather than the insecure API listener, so nothing but the two public entry points
is reachable. A third entry point, `ping` on 8082, is never published and only serves the
container healthcheck.

**dnsmasq** is configured entirely through command-line flags, with no mounted config file: the
TLD comes from a variable, the image's wrapper entrypoint is bypassed, `--no-resolv` and
`--no-hosts` isolate it from the container's own resolver, and logs go to stderr so
`make shared-logs svc=dnsmasq` shows them. It answers `127.0.0.1` for every `*.test` name and
forwards everything else to 1.1.1.1 and 8.8.8.8.

It is bound to the loopback address on purpose. Published on `0.0.0.0` it would be an open
resolver for the whole local network. Port 53 is free on `127.0.0.1` even where systemd-resolved
runs, since its stub listeners sit on `127.0.0.53` and `127.0.0.54`.

## Per project

| Service | Container | Image | Volume |
|---------|-----------|-------|--------|
| hybridly | `{p}-hybridly` | built locally, `dev` stage | none, bind mount |
| mysql | `{p}-mysql` | built locally on `mysql:9.7.2` | `{p}-mysql-data` |
| redis | `{p}-redis` | `redis:8.10.2` | `{p}-redis-data` |
| mail | `{p}-mail` | `axllent/mailpit:v1.31.2` | `{p}-mail-data` |
| rustfs | `{p}-rustfs` | `rustfs/rustfs:latest` | `{p}-rustfs-data` |
| rustfs-init | `{p}-rustfs-init` | minio client | none, exits after running |

Services that Traefik routes to (hybridly, mail, rustfs) join both the project network and the
shared one.

**hybridly** mounts the application directory and the certificates, publishes the Vite port
directly, and carries `extra_hosts` entries pointing the application's own public names at the
host gateway. Without them the application could not reach its own S3 API from inside a container:
dnsmasq answers `127.0.0.1`, which inside a container is the container itself.

**mysql** is built locally only to fix the pid file directory and silence a warning. Its init
script creates the testing database, and **only runs on the very first initialisation of the
volume**.

**rustfs** exposes the S3 API on 9000 and a console on 9001, so it declares two routers and two
services. Since it cannot create a bucket from an environment variable, an init container creates
it with the minio client and exits.

## Ordering

The only `depends_on` is between `rustfs-init` and `rustfs`. Everything else starts in parallel,
and healthchecks are indicators rather than barriers.
