# Makefile for Helm Chart Operations

# Variables
SHELL := /bin/bash

# Define chart directories
CHARTS := charts/kompass-compute charts/kompass-compute-crd

.PHONY: all
all: lint ensure-template-var-prefix template docs ## Run all operations that validate the correctness and generate assets

.PHONY: lint
lint: ## Lint all Helm charts
	@echo "Linting Helm charts..."
	@for chart in $(CHARTS); do \
		echo "Linting chart in $$chart..."; \
		helm lint $$chart || exit 1; \
	done

.PHONY: template
template: ## Template all Helm charts and validate output
	@echo "Templating Helm charts..."
	@for chart in $(CHARTS); do \
		echo "Templating chart from $$chart..."; \
		helm template test-release $$chart --debug > /dev/null || exit 1; \
	done

TEMPLATE_PREFIX := kompass-compute
.PHONY: ensure-template-var-prefix
ensure-template-var-prefix: ## Ensure all template variables start with "$(TEMPLATE_PREFIX)."
	@problem_keys=$$(find . -type f -name '*.tpl' \
		| xargs grep -Eo '{{-?[[:space:]]*define[[:space:]]*"[^"]+"' \
		| sed -E 's/.*define[[:space:]]*"([^"]+)".*/\1/' \
		| grep -v '^$(TEMPLATE_PREFIX)\.'); \
	if [ -n "$$problem_keys" ]; then \
		echo "Some template variables do not start with '$(TEMPLATE_PREFIX).' prefix."; \
		echo "$$problem_keys"; \
		exit 1; \
	fi

HELM_DOCS_IGNORE_REGEX := ".*\.readinessProbe\..*,.*\.startupProbe\..*,.*\.livenessProbe\..*,.*\.podSecurityContext\..*,.*\.securityContext\..*,.*\.resources\..*,.*\.podAnnotations\..*,.*\.tolerations\..*,.*\.podDisruptionBudget\..*,qubexConfig.infraConfig"
.PHONY: docs
docs: ## Generate documentation from values.yaml using helm-docs for all charts
	@echo "Generating documentation using helm-docs for all charts..."
	@if command -v helm-docs >/dev/null 2>&1; then \
		echo "Generating docs for $$chart"; \
		(cd charts/kompass-compute && helm-docs -t internal/README.md.gotmpl --documentation-strict-mode --documentation-strict-ignore-absent-regex $(HELM_DOCS_IGNORE_REGEX)); \
	else \
		echo "WARNING: helm-docs not found. Skipping documentation generation."; \
	fi
