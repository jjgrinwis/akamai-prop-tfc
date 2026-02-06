#!/usr/bin/env bash
# Script to create/ensure TFC workspace exists before terraform init

set -e

# Detect if we're in an environment directory
CURRENT_DIR=$(basename "$(pwd)")

# Determine the expected workspace name based on directory
EXPECTED_WORKSPACE="akamai-prop-${CURRENT_DIR}"

if [ -f "backend.tf" ]; then
    # Extract configuration from backend.tf (ignore comment lines)
    TFC_WORKSPACE_CURRENT=$(grep -v '^[[:space:]]*#' backend.tf | grep 'name' | head -1 | sed 's/.*name.*=.*"\(.*\)".*/\1/' | tr -d ' ')
    TFC_PROJECT_DEFAULT=$(grep -v '^[[:space:]]*#' backend.tf | grep 'project' | sed 's/.*project.*=.*"\(.*\)".*/\1/' | tr -d ' ')
    TFC_ORG_DEFAULT=$(grep -v '^[[:space:]]*#' backend.tf | grep 'organization' | sed 's/.*organization.*=.*"\(.*\)".*/\1/' | tr -d ' ')
    
    # Update or insert workspace name field
    if [ -z "$TFC_WORKSPACE_CURRENT" ]; then
        echo "📝 Adding workspace name to backend.tf: $EXPECTED_WORKSPACE"
        # Insert name field after the workspaces { line
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "/workspaces[[:space:]]*{/a\\
      name    = \"${EXPECTED_WORKSPACE}\"
" backend.tf
        else
            sed -i "/workspaces[[:space:]]*{/a\\      name    = \"${EXPECTED_WORKSPACE}\"" backend.tf
        fi
        echo "✅ backend.tf updated"
    elif [ "$TFC_WORKSPACE_CURRENT" != "$EXPECTED_WORKSPACE" ]; then
        echo "📝 Updating backend.tf workspace name: $TFC_WORKSPACE_CURRENT → $EXPECTED_WORKSPACE"
        # Update existing workspace name
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|name[[:space:]]*=[[:space:]]*\"${TFC_WORKSPACE_CURRENT}\"|name    = \"${EXPECTED_WORKSPACE}\"|" backend.tf
        else
            sed -i "s|name[[:space:]]*=[[:space:]]*\"${TFC_WORKSPACE_CURRENT}\"|name    = \"${EXPECTED_WORKSPACE}\"|" backend.tf
        fi
        echo "✅ backend.tf updated"
    fi
else
    echo "❌ backend.tf not found in current directory"
    echo "   Please run this script from an environment directory"
    exit 1
fi

# Set defaults if not found in backend.tf
TFC_PROJECT_DEFAULT="${TFC_PROJECT_DEFAULT:-mendix}"
TFC_ORG_DEFAULT="${TFC_ORG_DEFAULT:-grinwis-com}"

# Configuration
TFC_ORG="${TFC_ORGANIZATION:-${TFC_ORG_DEFAULT}}"
TFC_PROJECT="${TFC_PROJECT:-${TFC_PROJECT_DEFAULT}}"
TFC_WORKSPACE="$EXPECTED_WORKSPACE"

# Use directory name as environment identifier
ENVIRONMENT="$CURRENT_DIR"

# Default tags based on environment
DEFAULT_TAGS="environment:${ENVIRONMENT},project:${TFC_PROJECT}"

# Read optional tags from .workspace-tags file in current directory
# This allows each environment to have its own unique tags
TAGS_FILE=".workspace-tags"
FILE_TAGS=""
if [ -f "$TAGS_FILE" ]; then
    # Read tags from file, strip whitespace and comments
    FILE_TAGS=$(grep -v '^#' "$TAGS_FILE" 2>/dev/null | grep -v '^[[:space:]]*$' | tr '\n' ',' | sed 's/,$//')
    if [ -n "$FILE_TAGS" ]; then
        echo "📋 Found tags file: $TAGS_FILE"
    fi
fi

# Combine all tags: default + file + environment variable
TAGS="$DEFAULT_TAGS"
if [ -n "$FILE_TAGS" ]; then
    TAGS="${TAGS},${FILE_TAGS}"
fi
# Allow custom tags via environment variable (comma-separated)
# Example: export TFC_TAGS="team:platform,cost-center:123"
if [ -n "$TFC_TAGS" ]; then
    TAGS="${TAGS},${TFC_TAGS}"
fi

echo "🏷️  Tags to apply: $TAGS"

# Check if TFC token is set
if [ -z "$TFC_TOKEN" ]; then
    echo "⚠️  TFC_TOKEN not set. Checking for credentials file..."
    if [ ! -f "$HOME/.terraform.d/credentials.tfrc.json" ]; then
        echo "❌ No TFC credentials found."
        echo "   Please run: terraform login"
        exit 1
    fi
    echo "✓ Found TFC credentials file"
fi

# Use TFC API to check if workspace exists
echo "🔍 Checking if workspace '$TFC_WORKSPACE' exists in project '$TFC_PROJECT'..."

# Get auth token from credentials file or environment
if [ -n "$TFC_TOKEN" ]; then
    TOKEN="$TFC_TOKEN"
else
    TOKEN=$(jq -r '.credentials."app.terraform.io".token' "$HOME/.terraform.d/credentials.tfrc.json" 2>/dev/null || echo "")
fi

if [ -z "$TOKEN" ]; then
    echo "❌ Could not retrieve TFC token"
    exit 1
fi

# Check if workspace exists
WORKSPACE_CHECK=$(curl -s \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/organizations/$TFC_ORG/workspaces/$TFC_WORKSPACE" \
    | jq -r '.data.id // empty' 2>/dev/null || echo "")

if [ -n "$WORKSPACE_CHECK" ]; then
    echo "✓ Workspace '$TFC_WORKSPACE' already exists"

    # Update workspace settings (auto-apply)
    echo "🔧 Updating workspace settings..."
    SETTINGS_UPDATE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        --header "Authorization: Bearer $TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        --request PATCH \
        "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_CHECK" \
        --data '{
            "data": {
                "type": "workspaces",
                "attributes": {
                    "auto-apply": true
                }
            }
        }')

    SETTINGS_HTTP_CODE=$(echo "$SETTINGS_UPDATE" | grep "HTTP_CODE:" | cut -d: -f2)

    if [ "$SETTINGS_HTTP_CODE" = "200" ]; then
        echo "✅ Auto-apply enabled"
    else
        echo "⚠️  Warning: Settings update returned HTTP $SETTINGS_HTTP_CODE"
    fi

    echo "🏷️  Updating tags: $TAGS"

    # Update tags using the relationships/tags endpoint
    # First, convert tags to JSON array of tag objects
    TAG_OBJECTS=$(echo "$TAGS" | tr ',' '\n' | jq -R -s -c '
        split("\n") |
        map(select(length > 0)) |
        map({type: "tags", attributes: {name: .}})
    ')

    UPDATE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        --header "Authorization: Bearer $TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        --request POST \
        "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_CHECK/relationships/tags" \
        --data "{\"data\": $TAG_OBJECTS}")

    HTTP_CODE=$(echo "$UPDATE_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

    if [ "$HTTP_CODE" = "204" ]; then
        echo "✅ Tags updated successfully"
    else
        echo "⚠️  Warning: Tag update returned HTTP $HTTP_CODE"
        RESPONSE_BODY=$(echo "$UPDATE_RESPONSE" | sed '/HTTP_CODE:/d')
        echo "$RESPONSE_BODY" | jq '.errors // .' 2>/dev/null || echo "$RESPONSE_BODY"
    fi
else
    echo "📝 Creating workspace '$TFC_WORKSPACE' with tags: $TAGS"
    
    # Get project ID first
    PROJECT_ID=$(curl -s \
        --header "Authorization: Bearer $TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        "https://app.terraform.io/api/v2/organizations/$TFC_ORG/projects" \
        | jq -r ".data[] | select(.attributes.name == \"$TFC_PROJECT\") | .id" 2>/dev/null || echo "")
    
    if [ -z "$PROJECT_ID" ]; then
        echo "❌ Project '$TFC_PROJECT' not found in organization '$TFC_ORG'"
        echo "   Please create the project first in Terraform Cloud"
        exit 1
    fi
    
    # Detect working directory based on current location
    # If we're in an environment subdirectory, we need to set the working directory
    if [[ "$(pwd)" == *"/environments/"* ]]; then
        # Extract the relative path from repo root (e.g., "environments/dev")
        WORKING_DIR=$(pwd | sed 's|.*/akamai-prop-tfc/||')
        echo "   Setting working directory to: $WORKING_DIR"
    else
        WORKING_DIR=""
    fi
    
    # Convert comma-separated tags to JSON array
    TAG_ARRAY=$(echo "$TAGS" | tr ',' '\n' | jq -R -s -c 'split("\n") | map(select(length > 0))')
    
    # Create workspace with tags and working directory
    CREATE_RESPONSE=$(curl -s \
        --header "Authorization: Bearer $TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        --request POST \
        --data @- \
        "https://app.terraform.io/api/v2/organizations/$TFC_ORG/workspaces" <<EOF
{
  "data": {
    "type": "workspaces",
    "attributes": {
      "name": "$TFC_WORKSPACE",
      "execution-mode": "remote",
      "auto-apply": true,
      "terraform-version": "latest",
      "working-directory": "$WORKING_DIR",
      "tag-names": $TAG_ARRAY
    },
    "relationships": {
      "project": {
        "data": {
          "type": "projects",
          "id": "$PROJECT_ID"
        }
      }
    }
  }
}
EOF
)
    
    CREATED_ID=$(echo "$CREATE_RESPONSE" | jq -r '.data.id // empty' 2>/dev/null || echo "")
    
    if [ -n "$CREATED_ID" ]; then
        echo "✅ Workspace '$TFC_WORKSPACE' created successfully"
        
        # Apply tags to newly created workspace using relationships endpoint
        echo "🏷️  Applying tags: $TAGS"
        TAG_OBJECTS=$(echo "$TAGS" | tr ',' '\n' | jq -R -s -c '
            split("\n") | 
            map(select(length > 0)) | 
            map({type: "tags", attributes: {name: .}})
        ')
        
        TAG_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
            --header "Authorization: Bearer $TOKEN" \
            --header "Content-Type: application/vnd.api+json" \
            --request POST \
            "https://app.terraform.io/api/v2/workspaces/$CREATED_ID/relationships/tags" \
            --data "{\"data\": $TAG_OBJECTS}")
        
        TAG_HTTP_CODE=$(echo "$TAG_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
        
        if [ "$TAG_HTTP_CODE" = "204" ]; then
            echo "✅ Tags applied successfully"
        else
            echo "⚠️  Warning: Tag application returned HTTP $TAG_HTTP_CODE"
        fi
    else
        echo "❌ Failed to create workspace"
        echo "$CREATE_RESPONSE" | jq '.' 2>/dev/null || echo "$CREATE_RESPONSE"
        exit 1
    fi
fi

echo ""
echo "🚀 Running terraform init..."
terraform init

echo ""
echo "✅ Initialization complete!"
