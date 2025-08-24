# Makefile for Helm Chart Operations

# Variables
SHELL := /bin/bash

# Define chart directories
CHARTS := charts/kompass-compute charts/kompass-compute-crd

.PHONY: all
all: lint template docs ## Run all operations: lint, template and docs

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

.PHONY: ensure-template-var-prefix
ensure-template-var-prefix: ## Ensure all template variables start with "kompass-core."
	@sh hack/ensure-template-var-prefix.sh

HELM_DOCS_IGNORE_REGEX := ".*\.readinessProbe\..*,.*\.startupProbe\..*,.*\.livenessProbe\..*,.*\.podSecurityContext\..*,.*\.securityContext\..*,.*\.resources\..*,.*\.podAnnotations\..*,.*\.tolerations\..*,.*\.podDisruptionBudget\..*,qubexConfig.infraConfig"
.PHONY: docs
docs: ## Generate documentation from values.yaml using helm-docs for all charts
	@echo "Generating documentation using helm-docs for all charts..."
	@if command -v helm-docs >/dev/null 2>&1; then \
		for chart in $(CHARTS); do \
			echo "Generating docs for $$chart"; \
			(cd $$chart && helm-docs --documentation-strict-mode --documentation-strict-ignore-absent-regex $(HELM_DOCS_IGNORE_REGEX)); \
		done; \
		echo "Documentation generated in README.md files"; \
	else \
		echo "WARNING: helm-docs not found. Skipping documentation generation."; \
	fi
