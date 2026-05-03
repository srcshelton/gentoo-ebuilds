SHELL := /bin/bash

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
WORKFLOW ?= $(REPO_ROOT)/.github/workflows/cix-kernel-debs.yml
ACT_EVENT ?= workflow_dispatch
ACT_JOB ?=
ACT_PLATFORM ?= ubuntu-24.04-arm
ACT_RUNNER_IMAGE ?= ghcr.io/catthehacker/ubuntu:act-24.04
ACT_CONTAINER_ARCH ?= linux/arm64
ACT_MATRIX ?=
ACT_ARTIFACTS ?= $(REPO_ROOT)/.github/act-artifacts
ACT_EVENT_FILE ?= $(REPO_ROOT)/.github/act-event.json
ACT_EXTRA_ARGS ?=
CONTAINER_CPUS ?= 8
CONTAINER_MEMORY ?= 32g
CONTAINER_WORKDIR ?= /workspace
ACT_INSTALL_URL ?= https://raw.githubusercontent.com/nektos/act/master/install.sh

.PHONY: help act clean-act

help:
	@printf '%s\n' \
		'Targets:' \
		'  act        Run the CIX kernel workflow locally inside ghcr.io/catthehacker/ubuntu:act-24.04.' \
		'  clean-act  Remove local act event and artifact output.' \
		'' \
		'Variables:' \
		'  ACT_JOB=discover       Run one job only.' \
		'  ACT_MATRIX=k:v ...     Filter matrix entries, for example board_package:o6-acpi version:<selected-version>.' \
		'  ACT_EXTRA_ARGS=...     Pass extra flags to act.' \
		'  ACT_RUNTIME=docker     Force container, podman, or docker.' \
		'  CONTAINER_CPUS=8       CPU allocation for Apple container/podman/docker.' \
		'  CONTAINER_MEMORY=32g   Memory allocation for Apple container/podman/docker.'

act:
	@set -euo pipefail; \
	mkdir -p "$(ACT_ARTIFACTS)"; \
	printf '{"inputs":{"publish_release":false}}\n' > "$(ACT_EVENT_FILE)"; \
	trap 'rm -f "$(ACT_EVENT_FILE)"' EXIT; \
	runtime="$${ACT_RUNTIME:-}"; \
	if [[ -n "$${runtime}" ]]; then \
		runtimes=("$${runtime}"); \
	else \
		runtimes=(container podman docker); \
	fi; \
	selected=""; \
	for candidate in "$${runtimes[@]}"; do \
		if ! command -v "$${candidate}" >/dev/null 2>&1; then \
			printf 'Skipping %s: command not found\n' "$${candidate}" >&2; \
			continue; \
		fi; \
		printf 'Checking %s with %s\n' "$${candidate}" "$(ACT_RUNNER_IMAGE)" >&2; \
		case "$${candidate}" in \
			container) \
				container system start >/dev/null 2>&1 || true; \
				if container run --rm --arch arm64 "$(ACT_RUNNER_IMAGE)" true; then \
					selected="$${candidate}"; \
					break; \
				fi \
				;; \
			podman) \
				podman machine start >/dev/null 2>&1 || true; \
				if podman run --rm --platform "$(ACT_CONTAINER_ARCH)" "$(ACT_RUNNER_IMAGE)" true; then \
					selected="$${candidate}"; \
					break; \
				fi \
				;; \
			docker) \
				if docker run --rm --platform "$(ACT_CONTAINER_ARCH)" "$(ACT_RUNNER_IMAGE)" true; then \
					selected="$${candidate}"; \
					break; \
				fi \
				;; \
			*) \
				printf 'Unsupported ACT_RUNTIME=%s\n' "$${candidate}" >&2; \
				exit 2 \
				;; \
		esac; \
	done; \
	if [[ -z "$${selected}" ]]; then \
		printf 'No usable container runtime found. Tried: %s\n' "$${runtimes[*]}" >&2; \
		exit 1; \
	fi; \
	printf 'Running workflow with %s using %s\n' "$${selected}" "$(ACT_RUNNER_IMAGE)"; \
	inner='set -euo pipefail; \
		cd "$(CONTAINER_WORKDIR)"; \
		if ! command -v curl >/dev/null 2>&1; then \
			apt-get update; \
			apt-get install -y --no-install-recommends ca-certificates curl; \
			rm -rf /var/lib/apt/lists/*; \
		fi; \
		if ! command -v act >/dev/null 2>&1; then \
			curl -fsSL "$(ACT_INSTALL_URL)" | bash -s -- -b /usr/local/bin; \
		fi; \
		act --version; \
		job_args=(); \
		if [[ -n "$(ACT_JOB)" ]]; then \
			job_args=(-j "$(ACT_JOB)"); \
		fi; \
		matrix_args=(); \
		for matrix_entry in $(ACT_MATRIX); do \
			matrix_args+=(--matrix "$${matrix_entry}"); \
		done; \
		act "$(ACT_EVENT)" \
			--workflows "$(CONTAINER_WORKDIR)/.github/workflows/$(notdir $(WORKFLOW))" \
			--eventpath "$(CONTAINER_WORKDIR)/.github/$(notdir $(ACT_EVENT_FILE))" \
			--artifact-server-path "$(CONTAINER_WORKDIR)/.github/act-artifacts" \
			--platform "$(ACT_PLATFORM)=-self-hosted" \
			--container-architecture "$(ACT_CONTAINER_ARCH)" \
			"$${job_args[@]}" \
			"$${matrix_args[@]}" \
			$(ACT_EXTRA_ARGS)'; \
	case "$${selected}" in \
		container) \
			container run --rm \
				--arch arm64 \
				--cpus "$(CONTAINER_CPUS)" \
				--memory "$(CONTAINER_MEMORY)" \
				--volume "$(REPO_ROOT):$(CONTAINER_WORKDIR)" \
				--workdir "$(CONTAINER_WORKDIR)" \
				"$(ACT_RUNNER_IMAGE)" \
				bash -lc "$${inner}" \
			;; \
		podman) \
			podman run --rm \
				--platform "$(ACT_CONTAINER_ARCH)" \
				--cpus "$(CONTAINER_CPUS)" \
				--memory "$(CONTAINER_MEMORY)" \
				--volume "$(REPO_ROOT):$(CONTAINER_WORKDIR)" \
				--workdir "$(CONTAINER_WORKDIR)" \
				"$(ACT_RUNNER_IMAGE)" \
				bash -lc "$${inner}" \
			;; \
		docker) \
			docker run --rm \
				--platform "$(ACT_CONTAINER_ARCH)" \
				--cpus "$(CONTAINER_CPUS)" \
				--memory "$(CONTAINER_MEMORY)" \
				--volume "$(REPO_ROOT):$(CONTAINER_WORKDIR)" \
				--workdir "$(CONTAINER_WORKDIR)" \
				"$(ACT_RUNNER_IMAGE)" \
				bash -lc "$${inner}" \
			;; \
	esac

clean-act:
	@rm -rf "$(ACT_ARTIFACTS)" "$(ACT_EVENT_FILE)"
