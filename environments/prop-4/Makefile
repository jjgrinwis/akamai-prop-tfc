# Environment-specific Makefile
# This Makefile can be copied to any environment directory
# Workspace name is automatically derived from directory name

TF ?= terraform
TFLINT ?= tflint
ENV_DIR := $(shell basename $(CURDIR))
WORKSPACE_NAME := akamai-prop-$(ENV_DIR)

.PHONY: init plan apply destroy destroy-all help fmt fmt-check validate lint clean

help:
	@echo "Environment: $(ENV_DIR)"
	@echo "Workspace: $(WORKSPACE_NAME)"
	@echo ""
	@echo "Available targets:"
	@echo "  init        - Run validations, initialize and create TFC workspace"
	@echo "  plan        - Plan changes"
	@echo "  apply       - Apply changes"
	@echo "  destroy     - Destroy resources only"
	@echo "  destroy-all - Destroy resources and delete TFC workspace"
	@echo "  fmt         - Format Terraform files"
	@echo "  fmt-check   - Check if files are formatted"
	@echo "  validate    - Validate Terraform configuration"
	@echo "  lint        - Run tflint"
	@echo "  clean       - Remove .terraform directory"

fmt:
	@echo "🎨 Formatting Terraform files..."
	@$(TF) fmt -recursive

fmt-check:
	@echo "🔍 Checking Terraform formatting..."
	@$(TF) fmt -check -recursive || (echo "❌ Files need formatting. Run 'make fmt'" && exit 1)

validate:
	@echo "✅ Validating Terraform configuration..."
	@$(TF) validate

lint:
	@echo "🔎 Running tflint..."
	@if command -v $(TFLINT) >/dev/null 2>&1; then \
		$(TFLINT) --init && $(TFLINT); \
	else \
		echo "⚠️  tflint not installed. Skipping..."; \
		echo "   Install: https://github.com/terraform-linters/tflint"; \
	fi

init: fmt-check lint
	@echo "🔧 Initializing $(WORKSPACE_NAME)..."
	@../../scripts/init-tfc-workspace.sh
	@$(MAKE) validate

plan:
	@$(TF) plan

apply:
	@$(TF) apply

destroy:
	@$(TF) destroy

destroy-all:
	@echo "⚠️  This will destroy all resources AND delete the TFC workspace"
	@$(MAKE) destroy
	@../../scripts/delete-tfc-workspace.sh

clean:
	@echo "🧹 Cleaning up..."
	@rm -rf .terraform .terraform.lock.hcl
