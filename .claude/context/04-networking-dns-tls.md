# 04 - Networking, DNS and TLS

## The full path

```
Browser asks for https://app.{project}.test
  -> the OS resolver routes .test queries to dnsmasq on 127.0.0.1:53
  -> dnsmasq answers 127.0.0.1 for every *.test name
  -> Traefik listens on 443, terminates TLS with the mkcert certificate
  -> Traefik reads the Docker labels and forwards to the container's internal port
  -> FrankenPHP and Octane on 8000
```

## DNS

The TLD is hardcoded to `.test`, the only IETF-reserved TLD guaranteed never to collide with a
real domain. Do not make it configurable.

`make setup-dns` points the OS resolver at dnsmasq and picks the mechanism that fits:

- **macOS**: a resolver file under `/etc/resolver/`. macOS resolves per domain by design, so it
  never conflicts with anything else.
- **Linux with NetworkManager**: a dedicated profile carried by a dummy interface, holding the
  dnsmasq address and a routing domain for the TLD. That interface must carry a regular private
  address: systemd-resolved treats a link holding only a link-local address as irrelevant, gives
  it no DNS scope, and the routing domain is then never used. A routing domain attached to a link is more
  specific than a global one, which is how VPNs route their own domains, so it always wins. The
  profile survives reboots on its own, with no systemd unit.
- **Linux without NetworkManager**: a systemd-resolved drop-in holding the same server and routing
  domain in the global scope.

The NetworkManager path exists because systemd-resolved does not bind a server to a domain inside
its global scope: every global server is a candidate for every global routing domain. A machine
that already pins its own resolver with a global `Domains=~.` will therefore answer `.test`
queries from that resolver. `make setup-dns` detects this case and warns when it cannot avoid it.

`make restore-dns` removes whichever mechanism is present. Both need elevated privileges.

## TLS

`make update-certificates` installs the mkcert CA if it is not already trusted, generates a
wildcard certificate for the project and another for the shared stack, rebuilds the Traefik
certificate list, and copies the root CA into the image build context.

The certificates are consumed in three places: Traefik terminates TLS with them, Vite serves the
dev server over HTTPS with them, and the application container trusts the root CA so its outgoing
calls to the local S3 API succeed.

**`update-certificates` must run before `build`.** The image copies the root CA at build time, so
building first produces a container that does not trust the local domains.

mkcert only covers one wildcard level: `*.{project}.test` matches `app.{project}.test` but not a
deeper subdomain.

## Traefik configuration

Two public entry points, HTTP permanently redirecting to HTTPS. The Docker provider only routes
containers that opt in. A file provider watches the dynamic directory, where the certificate list
is regenerated, so a new project is picked up without restarting anything.

## Router naming

Every exposed service follows the same label pattern, and **every router and service name is
suffixed with the project name**. This is not decoration: a single Traefik now serves every
project, and two routers sharing a name would collide silently. The shared dashboard router uses
the shared project name for the same reason.

## Reaching the stack from inside a container

The application talks to its S3 API through the public URL. From inside a container, dnsmasq's
answer of `127.0.0.1` points at the container itself, so those names are mapped to the host
gateway with `extra_hosts`, where the shared Traefik listens.
