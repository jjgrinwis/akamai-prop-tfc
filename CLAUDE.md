# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Important**: All code changes must pass formatting (`make fmt-check`), linting (`make lint`), and validation before being committed.

## Working with Claude Code

### Before Starting a Session

**Always create a new branch before using Claude Code:**

```bash
# Make sure you're on your main branch and it's up to date
git checkout main
git pull

# Create a new branch for Claude's changes
git checkout -b claude/[feature-description]
```

Example branch names:

- `claude/refactor-auth`
- `claude/add-tests`
- `claude/fix-bug-123`
- `claude/optimize-queries`

### During the Session

- Claude Code will make changes across multiple files
- Changes are made directly to your working directory
- You can interrupt or guide Claude at any point

### After the Session

**Review the changes:**

```bash
# See what files were modified
git status

# Review all changes
git diff

# Review changes file by file
git diff path/to/file
```

**Commit the changes:**

```bash
# Stage all changes
git add .

# Commit with a descriptive message
git commit -m "feat: [description] (Claude Code assisted)"

# Or commit interactively to split into logical commits
git add -p
```

**Merge when ready:**

```bash
# Switch back to main
git checkout main

# Merge the Claude branch
git merge claude/[feature-description]

# Or create a PR for team review
git push origin claude/[feature-description]
```

### Reverting Changes

If you need to undo Claude's changes:

```bash
# Discard all uncommitted changes
git checkout .

# Or delete the branch entirely
git checkout main
git branch -D claude/[feature-description]
```

### Best Practices

- ✅ Create a new branch for each Claude Code session
- ✅ Review all changes before committing
- ✅ Test the code before merging to main
- ✅ Use descriptive commit messages
- ❌ Don't run Claude Code directly on main/master
- ❌ Don't commit without reviewing changes first

## Project Overview

This is a Terraform Cloud (TFC) workspace management system for deploying Akamai properties across multiple environments. It uses an environment-per-directory pattern where each subdirectory under `environments/` represents a separate TFC workspace with isolated state.

## Architecture

### Three-Layer Structure

1. **Modules** (`modules/`): Reusable Terraform modules
   - `akamai-property`: Manages Akamai property configurations (currently a placeholder)
   - `tfc-workspace-reader`: Queries TFC workspaces by tags and extracts their outputs

2. **Environments** (`environments/`): Environment-specific configurations
   - Each subdirectory is an independent environment with its own TFC workspace
   - Directory name determines workspace name: `environments/api.test.nl` → workspace `akamai-prop-api.test.nl`
   - Environment auto-detection via `locals { environment = basename(abspath(path.cwd)) }`

3. **Scripts** (`scripts/`): Automation helpers
   - `init-tfc-workspace.sh`: Creates/updates TFC workspaces with automatic tag application
   - `delete-tfc-workspace.sh`: Deletes TFC workspaces after resource destruction

### Key Design Patterns

**Workspace Naming**: Workspace names are automatically derived from directory names. The pattern is `akamai-prop-<directory-name>`. This is enforced by `scripts/init-tfc-workspace.sh` which auto-updates `backend.tf`.

**Environment Detection**: Each environment's `main.tf` uses `basename(abspath(path.cwd))` to auto-detect its environment name from the directory path. No manual configuration needed.

**Working Directory**: TFC workspaces have their `working-directory` set to `environments/<dir-name>` allowing module references like `../../modules/akamai-property`.

**Tag-Based Workspace Discovery**: The `tfc-workspace-reader` module uses TFC's tagging system to find related workspaces and aggregate their outputs (primarily hostnames). This enables cross-workspace data sharing via tags like `cert:cert-example`.

## Common Commands

All commands run from within an environment directory (e.g., `environments/example/`):

```bash
make init        # Run validations, create/update TFC workspace, then terraform init
make plan        # Preview changes
make apply       # Apply changes
make destroy     # Destroy resources only
make destroy-all # Destroy resources AND delete TFC workspace
make fmt         # Format Terraform files
make fmt-check   # Check formatting (fails if not formatted)
make validate    # Validate Terraform configuration
make lint        # Run tflint
make help        # Show available commands and workspace info
```

The `make init` command:

1. **Runs `fmt-check`** - Ensures all files are properly formatted
2. **Runs `lint`** - Executes tflint to catch issues (skips if tflint not installed)
3. Auto-detects workspace name from directory
4. Updates `backend.tf` if workspace name doesn't match
5. Creates workspace in TFC if it doesn't exist (or updates existing workspace)
6. **Enables auto-apply** on the workspace (no manual approval needed for applies)
7. Applies tags from `.workspace-tags` file and environment variables
8. Sets working directory to current path relative to repo root
9. Runs `terraform init`
10. **Runs `validate`** - Validates Terraform configuration

**Validation failures will prevent init from proceeding.**

### Root-Level Validation Commands

From the repository root, validate all modules and environments:

```bash
make fmt          # Format all Terraform files
make fmt-check    # Check all files are formatted
make validate-all # Validate all modules and examples
make lint         # Lint all directories
make pre-commit   # Run all validation checks (for CI/CD)
```

## Creating New Environments

```bash
# Copy example directory with desired name
cp -r environments/example environments/api.prod.acme.com
cd environments/api.prod.acme.com

# Create variable file (from template if exists)
cp api.prod.acme.com.auto.tfvars.template api.prod.acme.com.auto.tfvars
vim api.prod.acme.com.auto.tfvars  # Edit hostnames

# Optional: Add custom tags
cat > .workspace-tags <<EOF
cert:prod-wildcard
critical:true
EOF

# Initialize and deploy
make init
make plan
make apply
```

The workspace `akamai-prop-api.prod.acme.com` will be created automatically with tags:

- `environment:api.prod.acme.com` (automatic)
- `project:mendix` (from backend.tf)
- `cert:prod-wildcard` (from .workspace-tags)
- `critical:true` (from .workspace-tags)

## Destroying Environments

There are two ways to destroy an environment:

### Option 1: Destroy Resources Only (`make destroy`)

Destroys all Terraform-managed resources but keeps the TFC workspace:

```bash
cd environments/api.test.nl
make destroy
```

Use this when:

- You want to tear down infrastructure temporarily
- You plan to redeploy later using the same workspace
- You want to preserve workspace history and settings

### Option 2: Complete Cleanup (`make destroy-all`)

Destroys all resources AND deletes the TFC workspace:

```bash
cd environments/api.test.nl
make destroy-all
```

This will:

1. Run `terraform destroy` to remove all infrastructure
2. Prompt for confirmation before deleting the workspace
3. Delete the workspace from Terraform Cloud
4. Remove all workspace history and state

Use this when:

- You're permanently removing an environment
- You want complete cleanup with no remnants in TFC
- You're sure you won't need the workspace history

**Warning**: `make destroy-all` is irreversible. The workspace and its history will be permanently deleted from TFC.

## Tagging System

Tags are applied during `make init` from three sources (merged in order):

1. **Default tags** (automatic):
   - `environment:<directory-name>`
   - `project:<value-from-backend.tf>`

2. **File tags**: `.workspace-tags` in environment directory
   - Format: `key:value` (one per line)
   - Lines starting with `#` are comments

3. **Environment variable**: `TFC_TAGS`
   - Format: comma-separated `key:value` pairs
   - Example: `TFC_TAGS="team:platform,owner:john" make init`

See `docs/TAGGING.md` for comprehensive tagging documentation.

## TFC Configuration

- **Organization**: `grinwis-com`
- **Project**: `mendix`
- **Authentication**: Requires `TFC_TOKEN` environment variable or `terraform login`
- **State**: Stored remotely in TFC, one workspace per environment
- **Auto-apply**: Enabled by default on all workspaces (applies automatically after plan approval)

## Module Usage

### akamai-property Module

Currently contains a `null_resource` placeholder. When implementing Akamai resources:

- Add to `modules/akamai-property/main.tf`
- The module receives `environment` and `hostnames` variables from environments
- Keep resources generic; environment-specific values come from environment directories

### tfc-workspace-reader Module

Query workspaces by tag to aggregate outputs:

```hcl
module "cert_workspaces" {
  source = "../../modules/tfc-workspace-reader"

  organization = "grinwis-com"
  project      = "mendix"
  tag_filter   = "cert:cert-example"  # Find all workspaces with this tag
}

# Returns:
# - hostnames: Flat list of all hostnames from matching workspaces
# - workspace_hostnames: Map of workspace_name => hostnames
# - workspace_count: Number of matching workspaces
# - workspace_names: List of workspace names
```

Use case: Multiple environments share a certificate. Tag each environment with `cert:cert-example`, then use this module to collect all hostnames for certificate generation.

## File Structure Per Environment

```
environments/api.test.nl/
├── Makefile              # Copied from example, works in any environment
├── backend.tf            # TFC config, workspace name auto-updated by init script
├── main.tf               # Module instantiation with auto-detected environment
├── variables.tf          # Variable definitions
├── outputs.tf            # Outputs (must include hostnames for workspace-reader)
├── providers.tf          # Provider configuration
├── versions.tf           # Terraform and provider version constraints
├── .workspace-tags       # Optional custom tags (version controlled)
└── *.auto.tfvars         # Variable values (DO NOT commit, use .template files)
```

## Code Quality Standards

The project enforces code quality through automated validation:

- **Formatting**: All Terraform files must be formatted with `terraform fmt`
- **Linting**: Code is checked with `tflint` using `.tflint.hcl` configuration
- **Validation**: Terraform configurations must pass `terraform validate`

### Naming Conventions (enforced by tflint)

- Variables, outputs, locals, modules: `snake_case`
- All variables must have `type` and `description`
- All outputs must have `description`

### Running Validation

- `make fmt` - Auto-format code before committing
- `make init` - Automatically runs fmt-check, lint, and validate
- `make lint` - Manually run linting checks

See `docs/VALIDATION.md` for detailed validation documentation.

## Important Notes

- Never commit `*.auto.tfvars` files (contain environment-specific values)
- Do commit `.workspace-tags` files (workspace metadata)
- The `backend.tf` workspace name is auto-corrected by `make init`
- Running `make init` multiple times is safe; it's idempotent
- Each environment has completely isolated state in TFC
- The `examples/read-cert-workspaces/` directory demonstrates the workspace-reader module usage
- Always run `make fmt` before committing code
- If `make init` fails on validation, fix the issues before proceeding
