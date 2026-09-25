.EXPORT_ALL_VARIABLES:

# DNS config (hardcoded to .test, the only IETF-reserved TLD safe for local development)
DNS_DOMAIN := test
DNSMASQ_IP_ADDRESS := 127.0.0.1
DNSMASQ_FORWARD_PORT ?= 53

SHARED_PROJECT_NAME ?= localdev
SHARED_NETWORK_NAME ?= localdev

# Groups and users
GID ?= 1000
GROUP_NAME ?= laravel
UID ?= 1000
USER_NAME ?= laravel

# HTTP and HTTPS belong to the shared Traefik and never collide. The other three are published
# per project: override them in your Makefile to run several projects at the same time.
DB_FORWARD_PORT ?= 3306
HTTP_FORWARD_PORT ?= 80
HTTPS_FORWARD_PORT ?= 443
REDIS_FORWARD_PORT ?= 6379
VITE_PORT ?= 5173

# Versions
COMPOSER_VERSION ?= 2.10.3
DNSMASQ_VERSION ?= 2.93
MAILPIT_VERSION ?= v1.31.2
MINIO_CLIENT_VERSION ?= latest-dev
MYSQL_VERSION ?= 9.7.2
NODE_VERSION ?= 24
PHP_VERSION ?= 8.5
PNPM_VERSION ?= 12.6.0
REDIS_VERSION ?= 8.10.2
RUSTFS_VERSION ?= latest
TRAEFIK_VERSION ?= v3.7.13
XDEBUG_VERSION ?= 3.5.3
