COMPOSE_PROJECT_NAME ?= $(notdir $(PROJECT_DIRECTORY))
UNIX_SHELL_NAME := $(shell uname -s)

ifneq ($(strip $(OVERRIDE_PROJECT_NAME)),)
  COMPOSE_PROJECT_NAME := $(OVERRIDE_PROJECT_NAME)
endif

PROJECT_NAME_SLUG := $(shell echo $(COMPOSE_PROJECT_NAME) | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -d -c 'a-z0-9-')

export COMPOSE_PROJECT_NAME
export PROJECT_NAME_SLUG

CYAN   := \033[0;36m
GREEN  := \033[0;32m
RED    := \033[0;31m
RESET  := \033[0m
YELLOW := \033[0;33m

ifndef VERBOSE
	MAKEFLAGS += --no-print-directory
endif

DOCKER ?= @docker
DOCKER_COMPOSE ?= $(DOCKER) compose
HORIZON_EXEC ?= $(DOCKER_COMPOSE) exec -it horizon
HYBRIDLY_EXEC ?= $(DOCKER_COMPOSE) exec -it hybridly
HYBRIDLY_RUNNER ?= $(DOCKER_COMPOSE) run --rm --no-deps hybridly

MAKE_DIRECTORY := $(dir $(lastword $(MAKEFILE_LIST)))

include $(MAKE_DIRECTORY)/backend.mk
include $(MAKE_DIRECTORY)/certs.mk
include $(MAKE_DIRECTORY)/docker.mk
include $(MAKE_DIRECTORY)/environment.mk
include $(MAKE_DIRECTORY)/frontend.mk
include $(MAKE_DIRECTORY)/infra.mk
include $(MAKE_DIRECTORY)/install.mk

.PHONY: help
help:
	@echo 'Available make commands:'
	@grep -Eh '^[a-zA-Z_0-9%-]+:.*?## .*$$' Makefile $(MAKE_DIRECTORY)/*.mk | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "    - ${CYAN}%-25s${RESET}: %s\n", $$1, $$2}'
	@echo