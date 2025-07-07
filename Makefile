# Makefile for Helm Chart Operations

# Variables
SHELL := /bin/bash

# Define chart directories
CHARTS := charts/kompass-compute charts/kompass-compute-crd

.PHONY: all
all: compare-crds lint template docs ## Run all operations: lint, template and docs

.PHONY: compare-crds
compare-crds: ## Compare crds from charts/kompass-compute/crds and charts/kompass-compute-crd
	@echo "Comparing crd and templates folders..."
	@diff -r charts/kompass-compute/crds charts/kompass-compute-crd/templates || \
		{ echo "ERROR: Folders differ!"; exit 1; }

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

.PHONY: docs
docs: ## Generate documentation from values.yaml using helm-docs for all charts
	@echo "Generating documentation using helm-docs for all charts..."
	@if command -v helm-docs >/dev/null 2>&1; then \
		for chart in $(CHARTS); do \
			echo "Generating docs for $$chart"; \
			(cd $$chart && helm-docs); \
		done; \
		echo "Documentation generated in README.md files"; \
	else \
		echo "WARNING: helm-docs not found. Skipping documentation generation."; \
	fi
