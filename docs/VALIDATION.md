# Code Validation and Formatting

This project uses `terraform fmt` and `tflint` to ensure code quality and consistency.

## Automatic Validation

Validation runs automatically during `make init` in environment directories:

```bash
cd environments/example
make init
```

This will:
1. ✅ Check formatting with `terraform fmt -check`
2. ✅ Run linting with `tflint`
3. ✅ Initialize TFC workspace
4. ✅ Run `terraform init`
5. ✅ Validate configuration with `terraform validate`

If validation fails, `init` will not proceed.

## Manual Validation

### Format Terraform Code

```bash
# Format files in current directory
make fmt

# Check formatting without changes
make fmt-check
```

### Lint Terraform Code

```bash
# Run tflint on current directory
make lint
```

### Validate Configuration

```bash
# Validate Terraform configuration
make validate
```

## Root-Level Validation

Validate all modules, environments, and examples from repository root:

```bash
# Format all Terraform files
make fmt

# Check all formatting
make fmt-check

# Validate all modules and examples
make validate-all

# Lint all directories
make lint

# Run all checks (useful for CI/CD)
make pre-commit
```

## Installing TFLint

### macOS

```bash
brew install tflint
```

### Linux

```bash
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
```

### Manual Installation

Download from: https://github.com/terraform-linters/tflint/releases

## TFLint Configuration

The project uses `.tflint.hcl` in the root directory with these rules:

- **Naming conventions**: Enforces `snake_case` for variables, outputs, locals, modules
- **Documentation**: Requires descriptions for variables and outputs
- **Type safety**: Requires type constraints on variables
- **Deprecated syntax**: Disallows old Terraform syntax
- **Unused declarations**: Detects unused variables, outputs, etc.
- **Module structure**: Validates standard module layout

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Terraform Validation

on:
  pull_request:
    paths:
      - '**.tf'
      - '.tflint.hcl'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Install TFLint
        run: |
          curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

      - name: Format Check
        run: make fmt-check

      - name: Validate All
        run: make validate-all

      - name: Lint All
        run: make lint
```

### GitLab CI Example

```yaml
terraform-validate:
  image: hashicorp/terraform:1.5
  before_script:
    - apk add --no-cache curl bash
    - curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
  script:
    - make fmt-check
    - make validate-all
    - make lint
  only:
    changes:
      - "**/*.tf"
      - ".tflint.hcl"
```

## Pre-commit Hooks

Set up local pre-commit hooks to catch issues before commit:

### Option 1: Manual Git Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

echo "Running Terraform validation..."

# Check formatting
echo "Checking format..."
terraform fmt -check -recursive || {
  echo "❌ Formatting check failed. Run 'make fmt' to fix."
  exit 1
}

# Run tflint if available
if command -v tflint >/dev/null 2>&1; then
  echo "Running tflint..."
  make lint || {
    echo "❌ Linting failed."
    exit 1
  }
fi

echo "✅ All checks passed"
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

### Option 2: pre-commit Framework

Install: https://pre-commit.com/

Create `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
```

Install hooks:

```bash
pre-commit install
```

## Common Issues

### TFLint: Module Not Installed

**Error**: `Failed to load configurations; Module not installed`

**Solution**:
```bash
terraform init
make lint
```

### Formatting Issues

**Error**: `terraform fmt -check` fails

**Solution**:
```bash
make fmt  # Auto-format all files
```

### Variable Missing Description

**Error**: `variable "foo" should include a description`

**Solution**: Add description to variable:
```hcl
variable "foo" {
  type        = string
  description = "Description of what foo does"
}
```

### Variable Missing Type

**Error**: `variable "foo" should include a type`

**Solution**: Add type constraint:
```hcl
variable "foo" {
  type        = string
  description = "Description"
}
```

## Skipping Validation (Not Recommended)

To skip validation during init:

```bash
# Skip fmt check and lint, run init directly
../../scripts/init-tfc-workspace.sh
terraform init
```

However, it's strongly recommended to fix validation issues rather than skip them.

## Best Practices

1. **Run `make fmt` before committing** - Keep code consistently formatted
2. **Install tflint locally** - Catch issues before CI/CD
3. **Add descriptions to all variables and outputs** - Self-documenting code
4. **Use type constraints** - Catch type errors early
5. **Run `make validate-all` before pushing** - Ensure everything works
6. **Keep `.tflint.hcl` updated** - Review rules periodically

## Validation in Development Workflow

```bash
# 1. Create new environment
cd environments
cp -r example my-new-env
cd my-new-env

# 2. Edit configuration
vim main.tf

# 3. Format code
make fmt

# 4. Initialize (includes validation)
make init  # Runs fmt-check, lint, init, validate

# 5. Plan and apply
make plan
make apply
```

Validation is integrated into the normal workflow and catches issues early.
