# Terraform Cloud Environments

This directory contains individual environment configurations, each with its own isolated Terraform Cloud workspace.

## Quick Start

Creating a new environment is simple - just copy the example directory and run make init:

```bash
# 1. Copy the example directory with your desired name
cp -r example api.test.nl
cd api.test.nl

# 2. Update your variables (optional - modify hostnames)
cp api.test.nl.auto.tfvars.template api.test.nl.auto.tfvars
vim api.test.nl.auto.tfvars

# 3. Initialize (automatically creates workspace and updates backend.tf)
make init

# 4. Use Terraform
make plan
make apply
```

That's it! The workspace name, tags, and configuration are all automated.

## How It Works

### Automatic Configuration

When you run `make init`, the following happens automatically:

1. **Workspace Name Auto-Detection**
   - The workspace name is set to `akamai-prop-<directory-name>`
   - Example: Directory `api.test.nl` → Workspace `akamai-prop-api.test.nl`
   - The `backend.tf` file is automatically updated to match

2. **Environment Detection**
   - The environment variable is set to the directory name
   - Uses `locals { environment = basename(abspath(path.cwd)) }` in `main.tf`
   - No manual configuration needed

3. **Workspace Creation**
   - Creates the workspace in Terraform Cloud if it doesn't exist
   - Sets the working directory to `environments/<your-directory>`
   - This allows the workspace to access modules at `../../modules/`

4. **Tag Application**
   - Automatically applies tags during workspace creation:
     - `environment:<directory-name>` (e.g., `environment:api.test.nl`)
     - `project:mendix` (from backend.tf)
     - Any custom tags from `.workspace-tags` file

### Directory Structure

Each environment directory contains:

```
api.test.nl/
├── Makefile            # Local make commands (auto-detects workspace)
├── backend.tf          # TFC configuration (workspace name auto-updated)
├── main.tf             # Module instantiation (environment auto-detected)
├── variables.tf        # Variable definitions
├── outputs.tf          # Output definitions
├── providers.tf        # Provider configuration
├── versions.tf         # Version constraints
├── .workspace-tags     # Optional custom tags
└── *.auto.tfvars       # Variable values (create from template)
```

## Available Commands

Run these from within any environment directory:

```bash
make init        # Create/configure workspace and initialize Terraform
make plan        # Preview infrastructure changes
make apply       # Apply infrastructure changes
make destroy     # Destroy infrastructure resources only
make destroy-all # Destroy resources AND delete TFC workspace
make help        # Show available commands
```

## Customization

### Adding Custom Tags

Edit the `.workspace-tags` file in your environment directory:

```bash
# Example: .workspace-tags
cert:my-certificate-id
cost-center:engineering
critical:true
```

Tags are applied during `make init`. Format: `key:value` (one per line, no spaces in tag names).

### Changing Variables

Each environment needs its own variable file:

```bash
# Create from template
cp myenv.auto.tfvars.template myenv.auto.tfvars

# Edit with your values
vim myenv.auto.tfvars
```

Example content:

```hcl
hostnames = [
  "api.example.com",
  "www.example.com"
]
```

### Modifying Provider Configuration

Edit `providers.tf` to change:

- Akamai edgerc section
- Provider versions
- Other provider settings

## Examples

### Creating a Production API Environment

```bash
cp -r example api.prod.acme.com
cd api.prod.acme.com

# Create variables
cat > api.prod.acme.com.auto.tfvars <<EOF
hostnames = ["api.prod.acme.com"]
EOF

# Add custom tags
cat > .workspace-tags <<EOF
cert:prod-wildcard
sla:99-99
critical:true
EOF

# Initialize and deploy
make init
make plan
make apply
```

This creates workspace `akamai-prop-api.prod.acme.com` with tags:

- `environment:api.prod.acme.com`
- `project:mendix`
- `cert:prod-wildcard`
- `sla:99-99`
- `critical:true`

### Creating Multiple Environments

```bash
# Development
cp -r example dev.api.acme.com
cd dev.api.acme.com
echo 'hostnames = ["dev-api.acme.com"]' > dev.api.acme.com.auto.tfvars
make init && make apply

# Staging
cd ../
cp -r example staging.api.acme.com
cd staging.api.acme.com
echo 'hostnames = ["staging-api.acme.com"]' > staging.api.acme.com.auto.tfvars
make init && make apply

# Production
cd ../
cp -r example api.acme.com
cd api.acme.com
echo 'hostnames = ["api.acme.com"]' > api.acme.com.auto.tfvars
make init && make apply
```

Each gets its own isolated workspace and state file in Terraform Cloud.

## Destroying Environments

### Destroy Resources Only

To destroy infrastructure but keep the TFC workspace:

```bash
cd api.test.nl
make destroy
```

The workspace remains in TFC with its configuration, tags, and history. You can redeploy later with `make apply`.

### Complete Cleanup

To destroy infrastructure AND delete the TFC workspace:

```bash
cd api.test.nl
make destroy-all
```

This will:
1. Destroy all Terraform-managed resources
2. Ask for confirmation
3. Delete the workspace from Terraform Cloud

**Warning**: This permanently removes the workspace and its history from TFC. Use this only when completely removing an environment.

## Best Practices

### Naming Conventions

Use descriptive directory names that reflect the actual service or hostname:

- ✅ `api.test.nl`, `www.prod.acme.com`, `checkout-service`
- ❌ `env1`, `test`, `my-config`

The directory name becomes the environment identifier and part of the workspace name.

### Version Control

**Commit to Git:**

- All `.tf` files
- `.workspace-tags` file
- `Makefile`
- `.terraform.lock.hcl` (provider versions)

**Do NOT commit:**

- `*.auto.tfvars` files (contain environment-specific values)
- `.terraform/` directory
- Create `.auto.tfvars.template` files as examples instead

### State Management

- Each environment has its own isolated state in TFC
- State is automatically stored remotely (no local state files)
- Running `make init` is safe and won't affect existing state
- The workspace is locked during `apply` to prevent concurrent changes

### Workspace Organization in TFC

All workspaces are created in the same TFC organization and project:

- **Organization:** `grinwis-com`
- **Project:** `mendix`
- **Naming:** `akamai-prop-<directory-name>`

Use tags to filter and organize workspaces in the TFC UI.

## Troubleshooting

### Workspace Name Mismatch

If you see an error about workspace name:

```bash
# Re-run init to auto-correct the workspace name
make init
```

The script automatically updates `backend.tf` to match the directory name.

### Tags Not Showing

Tags are applied during workspace creation. If they're missing:

```bash
# Re-run the init script to update tags
../../scripts/init-tfc-workspace.sh
```

### Module Not Found Error

If you see `no such file or directory: ../../modules`:

1. Check that `backend.tf` has the workspace created
2. Verify `working-directory` is set correctly in TFC workspace
3. Run `make init` to reconfigure

### Wrong Environment Value

The environment is auto-detected from the directory name. If it's incorrect:

1. Check `main.tf` has: `locals { environment = basename(abspath(path.cwd)) }`
2. Verify you're in the correct directory
3. Run `terraform plan` to see the detected value

## CI/CD Integration

The Makefile works well in CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Terraform Init
  run: |
    cd environments/${{ matrix.environment }}
    make init

- name: Terraform Plan
  run: |
    cd environments/${{ matrix.environment }}
    make plan

- name: Terraform Apply
  run: |
    cd environments/${{ matrix.environment }}
    make apply
```

Set `TFC_TOKEN` environment variable in your CI system for authentication.

## Additional Resources

- **TFC Documentation:** https://developer.hashicorp.com/terraform/cloud-docs
- **Workspace Tagging:** See `.workspace-tags` examples in the example directory
- **Module Development:** See `../modules/akamai-property/` for shared resources
- **Scripts:** See `../scripts/` for automation details
