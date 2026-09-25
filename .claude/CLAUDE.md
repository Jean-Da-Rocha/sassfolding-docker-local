# Claude Instructions

## Project

Docker infrastructure for Laravel and Hybridly applications. **No application code lives here**:
only Dockerfiles, compose files and Makefiles.

The application repository is linked through the `DOCKER_DIRECTORY` environment variable.
`make` commands are always run **from the application directory**, never from here.

## Rules

- Local development only, never production
- Do not edit `make/infra.mk` for a project-specific need: override the variable in that
  project's Makefile, above the include line
- Any new Traefik route must suffix its router and service names with `${COMPOSE_PROJECT_NAME}`,
  otherwise it collides with the other projects sharing the same Traefik
- `update-certificates` always runs before `build`
- Do not make the TLD configurable, `.test` is hardcoded for a reason (RFC 6761)

## Commits

- Conventional Commits
- No co-author line
- Subject line only, no body
