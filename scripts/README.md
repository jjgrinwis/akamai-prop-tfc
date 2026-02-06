# Scripts

Automation scripts for managing Terraform Cloud workspaces.

## Available Scripts

### init-tfc-workspace.sh

Creates or updates a TFC workspace for the current environment.

**Usage:**
```bash
# Run from within an environment directory
cd environments/example
make init  # Calls this script automatically
```

**What it does:**
1. Auto-detects workspace name from directory name (`akamai-prop-<dir-name>`)
2. Updates `backend.tf` if workspace name doesn't match
3. Creates workspace in TFC if it doesn't exist
4. Configures workspace settings:
   - Enables auto-apply
   - Sets working directory to current environment path
   - Applies tags from multiple sources
5. Runs `terraform init`

**Tag Sources (merged in order):**
1. Default tags: `environment:<dir-name>`, `project:<from-backend.tf>`
2. File tags: `.workspace-tags` in environment directory
3. Environment variable: `TFC_TAGS` (comma-separated key:value pairs)

**Requirements:**
- Must be run from an environment directory with `backend.tf`
- TFC authentication via `TFC_TOKEN` environment variable or `~/.terraform.d/credentials.tfrc.json`

**Example:**
```bash
cd environments/api.prod.acme.com
../../scripts/init-tfc-workspace.sh
```

### delete-tfc-workspace.sh

Deletes a TFC workspace after resources have been destroyed.

**Usage:**
```bash
# Run from within an environment directory
cd environments/example
make destroy-all  # Destroys resources then calls this script

# Or manually:
../../scripts/delete-tfc-workspace.sh
```

**What it does:**
1. Auto-detects workspace name from directory name
2. Checks if workspace exists in TFC
3. Prompts for confirmation (type "yes" to proceed)
4. Deletes the workspace via TFC API
5. Permanently removes workspace history and state

**Requirements:**
- Must be run from an environment directory with `backend.tf`
- TFC authentication via `TFC_TOKEN` environment variable or credentials file
- Workspace should have no active resources (run `terraform destroy` first)

**Warning:** This action is irreversible. The workspace and its history will be permanently deleted from TFC.

**Example:**
```bash
cd environments/api.test.nl
terraform destroy  # Destroy resources first
../../scripts/delete-tfc-workspace.sh
# Type "yes" when prompted
```

## Authentication

Both scripts require Terraform Cloud authentication. Set up credentials using one of these methods:

### Method 1: Environment Variable
```bash
export TFC_TOKEN="your-tfc-token"
```

### Method 2: Terraform Login
```bash
terraform login
# Creates ~/.terraform.d/credentials.tfrc.json
```

## Common Workflows

### Creating a New Environment
```bash
cp -r environments/example environments/my-app
cd environments/my-app
make init  # Runs init-tfc-workspace.sh
make plan
make apply
```

### Updating Workspace Tags
```bash
cd environments/my-app
echo "team:platform" >> .workspace-tags
make init  # Re-runs init to update tags
```

### Complete Environment Removal
```bash
cd environments/my-app
make destroy-all  # Runs destroy + delete-tfc-workspace.sh
```

## Debugging

### Check Workspace Exists
```bash
# Using TFC API
curl -s \
  --header "Authorization: Bearer $TFC_TOKEN" \
  "https://app.terraform.io/api/v2/organizations/grinwis-com/workspaces/akamai-prop-example" \
  | jq '.data.attributes.name'
```

### View Workspace Tags
```bash
curl -s \
  --header "Authorization: Bearer $TFC_TOKEN" \
  "https://app.terraform.io/api/v2/workspaces/<workspace-id>/relationships/tags" \
  | jq '.data[].attributes.name'
```

### List All Workspaces in Project
```bash
# Use the list-workspaces.sh helper script
./scripts/list-workspaces.sh
```

## Error Handling

### "Project not found"
- Verify the project exists in TFC organization
- Check `backend.tf` has correct project name
- Ensure your TFC token has access to the project

### "Workspace already exists"
- The init script handles existing workspaces automatically
- It will update settings and tags on existing workspaces
- Safe to run multiple times

### "Could not retrieve TFC token"
- Run `terraform login` to authenticate
- Or set `TFC_TOKEN` environment variable
- Check token has correct permissions

### "Workspace name mismatch"
- The init script auto-corrects workspace names in `backend.tf`
- Workspace name is always `akamai-prop-<directory-name>`
- Re-run `make init` to fix

## Additional Resources

- [Terraform Cloud API Documentation](https://developer.hashicorp.com/terraform/cloud-docs/api-docs)
- [Workspace Tagging Guide](../docs/TAGGING.md)
- [Environment Setup Guide](../environments/README.md)
