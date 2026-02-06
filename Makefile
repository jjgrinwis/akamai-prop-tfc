# Root Makefile for validating all modules and environments
# Run from repository root

TF ?= terraform
TFLINT ?= tflint

# Find all directories with .tf files (modules, environments, examples)
TF_DIRS := $(shell find . -name "*.tf" -not -path "*/.terraform/*" -exec dirname {} \; | sort -u)
ENV_DIRS := $(shell find environments -mindepth 1 -maxdepth 1 -type d -not -name ".*")
MODULE_DIRS := $(wildcard modules/*)
EXAMPLE_DIRS := $(wildcard examples/*)

.PHONY: help fmt fmt-check validate lint validate-all clean

help:
	@echo "Root-level validation targets:"
	@echo ""
	@echo "  fmt           - Format all Terraform files"
	@echo "  fmt-check     - Check formatting of all Terraform files"
	@echo "  validate-all  - Validate all modules and environments"
	@echo "  lint          - Run tflint on all directories"
	@echo "  clean         - Remove all .terraform directories"
	@echo ""
	@echo "Directories to validate:"
	@echo "  Modules:      $(MODULE_DIRS)"
	@echo "  Environments: $(shell basename -a $(ENV_DIRS) | tr '\n' ' ')"
	@echo "  Examples:     $(EXAMPLE_DIRS)"

fmt:
	@echo "🎨 Formatting all Terraform files..."
	@$(TF) fmt -recursive

fmt-check:
	@echo "🔍 Checking formatting in all directories..."
	@$(TF) fmt -check -recursive || (echo "❌ Files need formatting. Run 'make fmt'" && exit 1)
	@echo "✅ All files properly formatted"

validate-all: fmt-check
	@echo "✅ Validating all modules..."
	@for dir in $(MODULE_DIRS); do \
		echo "  Validating $$dir..."; \
		cd $$dir && $(TF) init -backend=false >/dev/null && $(TF) validate || exit 1; \
		cd - >/dev/null; \
	done
	@echo "✅ All modules valid"
	@echo ""
	@echo "✅ Validating all examples..."
	@for dir in $(EXAMPLE_DIRS); do \
		echo "  Validating $$dir..."; \
		cd $$dir && $(TF) init -backend=false >/dev/null && $(TF) validate || exit 1; \
		cd - >/dev/null; \
	done
	@echo "✅ All examples valid"
	@echo ""
	@echo "ℹ️  Note: Environment validation requires 'make init' in each environment directory"

lint:
	@echo "🔎 Running tflint on all directories..."
	@if ! command -v $(TFLINT) >/dev/null 2>&1; then \
		echo "❌ tflint not installed"; \
		echo "   Install: https://github.com/terraform-linters/tflint"; \
		exit 1; \
	fi
	@for dir in $(TF_DIRS); do \
		echo "  Linting $$dir..."; \
		cd $$dir && $(TFLINT) --init >/dev/null 2>&1 && $(TFLINT) || exit 1; \
		cd - >/dev/null; \
	done
	@echo "✅ All linting checks passed"

clean:
	@echo "🧹 Cleaning all .terraform directories..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "✅ Cleanup complete"

# Pre-commit hook target
pre-commit: fmt-check validate-all lint
	@echo "✅ All pre-commit checks passed"
