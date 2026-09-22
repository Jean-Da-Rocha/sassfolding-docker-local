# Context index

Persistent context for this infrastructure repository. Read this first.

This repository holds **no application code**. It holds the Dockerfiles, compose files and
Makefiles that run an application living in a separate repository.

| File | Contents | When to read |
|------|----------|--------------|
| [00-overview.md](00-overview.md) | Role, link to the application, repository layout | Always |
| [01-services.md](01-services.md) | Services, compose, labels, healthchecks, volumes | Before touching a service |
| [02-hybridly-container.md](02-hybridly-container.md) | Multi-stage image, supervisor, PHP, Xdebug | Before changing the application image |
| [03-make-system.md](03-make-system.md) | Makefile layout, targets, variables | Before adding or changing a target |
| [04-networking-dns-tls.md](04-networking-dns-tls.md) | Traefik, dnsmasq, mkcert, name resolution | When a domain or a certificate misbehaves |
| [05-lifecycle.md](05-lifecycle.md) | Installation, daily operation, troubleshooting | To start, restart or repair the stack |
| [06-gotchas.md](06-gotchas.md) | Traps, constraints, known debt | When something behaves unexpectedly |

## Repository documentation (do not duplicate here)

`README.md` carries the public presentation, the full table of make commands and the advanced
sections: dnsmasq design choices, FrankenPHP and Octane, the Dockerfile stages, RustFS and its
init container.
