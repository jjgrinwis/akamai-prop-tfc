# Workspace Tagging Guide

## Overview

All TFC workspaces created by the init script are automatically tagged for easy filtering and organization.

## Default Tags

Every workspace gets these tags automatically:

| Tag                 | Description                           | Example                               |
| ------------------- | ------------------------------------- | ------------------------------------- |
| `terraform`         | Indicates Terraform-managed workspace | `terraform`                           |
| `automated`         | Created via automation script         | `automated`                           |
| `environment:<env>` | Environment name                      | `environment:dev`, `environment:prod` |
| `project:<name>`    | Project from backend.tf               | `project:mendix`                      |

## Adding Custom Tags

There are two ways to add custom tags:

### 1. Per-Environment Tags File (Recommended)

Create a `.workspace-tags` file in each environment directory:

```bash
# environments/dev/.workspace-tags
cert:cert01
team:platform
cost-center:dev-123
```

**Benefits:**

- Different tags per environment
- Version controlled with your code
- No environment variables needed
- Survives system reboots

**File format:**

- One tag per line
- Format: `key:value` or `simple-tag`
- Lines starting with `#` are comments
- Blank lines are ignored

**Example:**

```bash
# Certificate identifier
cert:cert01

# Team ownership
team:platform
owner:john@example.com

# Cost tracking
cost-center:dev-123
```

### 2. Environment Variable (Optional)

Add custom tags via the `TFC_TAGS` environment variable:

```bash
# Single workspace
export TFC_TAGS="team:platform,cost-center:engineering,owner:john"
cd environments/dev && make init

# Different tags for different environments
cd environments/prod && TFC_TAGS="critical:true,sla:99.9" make init
cd environments/dev && TFC_TAGS="critical:false" make init
```

**Note:** Tags from both sources are combined. Order of precedence:

1. Default tags (always included)
2. File tags (from `.workspace-tags`)
3. Environment variable tags (from `TFC_TAGS`)

## Filtering Workspaces

### In TFC UI

1. Navigate to your organization's workspaces
2. Use the filter dropdown to select tags
3. Example: Filter by `environment:dev` to see all dev workspaces

### Via CLI Script

Use the provided helper script:

```bash
# List all workspaces with tags
./scripts/list-workspaces.sh

# Filter by environment
./scripts/list-workspaces.sh environment:dev
./scripts/list-workspaces.sh environment:prod

# Filter by project
./scripts/list-workspaces.sh project:mendix

# Filter by custom tag
./scripts/list-workspaces.sh team:platform
./scripts/list-workspaces.sh cost-center:123
```

### Via TFC API

```bash
# Get workspaces with specific tag
curl -s \
  --header "Authorization: Bearer $TFC_TOKEN" \
  "https://app.terraform.io/api/v2/organizations/grinwis-com/workspaces" \
  | jq '.data[] | select(.attributes["tag-names"] | index("environment:dev"))'
```

## Common Tag Patterns

### Team Organization

```bash
TFC_TAGS="team:platform,squad:core,owner:alice@example.com"
```

### Cost Allocation

```bash
TFC_TAGS="cost-center:123,department:engineering,budget:operational"
```

### Compliance & Governance

```bash
TFC_TAGS="compliance:required,data-classification:internal,backup:enabled"
```

### Lifecycle Management

```bash
TFC_TAGS="lifecycle:permanent,destroy:manual-only,retention:7-years"
```

## Tag Naming Conventions

**Recommended format:** `category:value`

- Use lowercase
- Use hyphens for multi-word values
- Use colons to separate category from value
- Keep tags concise and meaningful

**Examples:**

- ✅ `environment:dev`, `cost-center:eng-123`, `owner:team-platform`
- ❌ `Dev Environment`, `Cost Center 123`, `Platform Team Owner`

## Benefits of Tagging

1. **Easy Filtering** - Quickly find related workspaces
2. **Cost Allocation** - Track costs by team, project, or department
3. **Automation** - Bulk operations on tagged workspaces
4. **Compliance** - Track data classification and requirements
5. **Organization** - Logical grouping of resources

## Updating Tags

Tags are automatically updated when you re-run init:

```bash
# Add new tags to existing workspace
export TFC_TAGS="new-tag:value"
cd environments/dev && make init  # Workspace already exists, tags will be updated
```

## Example Multi-Environment Setup

### Using .workspace-tags files (Recommended)

```bash
# environments/dev/.workspace-tags
cert:cert01
critical:false

# environments/staging/.workspace-tags
cert:cert02
critical:false

# environments/prod/.workspace-tags
cert:cert03
critical:true
sla:99.9

# Initialize each environment - each gets its unique tags
cd environments/dev && make init
cd environments/staging && make init
cd environments/prod && make init
```

### Using Environment Variables

```bash
# Development
cd environments/dev && TFC_TAGS="critical:false,auto-destroy:nightly" make init

# Staging
cd environments/staging && TFC_TAGS="critical:false,auto-destroy:weekly" make init

# Production
cd environments/prod && TFC_TAGS="critical:true,auto-destroy:never,sla:99.9" make init
```

### Combining Both Approaches

You can use both `.workspace-tags` files and environment variables together. They will be merged:

```bash
# environments/dev/.workspace-tags contains: cert:cert01
# Add additional tags via environment variable
cd environments/dev && TFC_TAGS="team:platform,owner:john" make init

# Result: terraform,automated,environment:dev,project:mendix,cert:cert01,team:platform,owner:john
```

Now you can filter all production workspaces with `critical:true`, find workspaces by certificate with `cert:cert01`, or locate auto-destroyable workspaces with `auto-destroy:nightly`.
