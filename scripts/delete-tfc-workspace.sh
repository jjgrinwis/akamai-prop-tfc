#!/usr/bin/env bash
# Script to delete TFC workspace after terraform destroy

set -e

# Detect if we're in an environment directory
CURRENT_DIR=$(basename "$(pwd)")

# Determine the workspace name based on directory
WORKSPACE_NAME="akamai-prop-${CURRENT_DIR}"

if [ -f "backend.tf" ]; then
    # Extract configuration from backend.tf (ignore comment lines)
    TFC_PROJECT_DEFAULT=$(grep -v '^[[:space:]]*#' backend.tf | grep 'project' | sed 's/.*project.*=.*"\(.*\)".*/\1/' | tr -d ' ')
    TFC_ORG_DEFAULT=$(grep -v '^[[:space:]]*#' backend.tf | grep 'organization' | sed 's/.*organization.*=.*"\(.*\)".*/\1/' | tr -d ' ')
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
TFC_WORKSPACE="$WORKSPACE_NAME"

echo "🗑️  Preparing to delete workspace '$TFC_WORKSPACE' from project '$TFC_PROJECT'..."

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
echo "🔍 Checking if workspace '$TFC_WORKSPACE' exists..."
WORKSPACE_CHECK=$(curl -s \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/organizations/$TFC_ORG/workspaces/$TFC_WORKSPACE" \
    | jq -r '.data.id // empty' 2>/dev/null || echo "")

if [ -z "$WORKSPACE_CHECK" ]; then
    echo "⚠️  Workspace '$TFC_WORKSPACE' does not exist in TFC"
    echo "   Nothing to delete"
    exit 0
fi

echo "✓ Workspace '$TFC_WORKSPACE' found (ID: $WORKSPACE_CHECK)"

# Prompt for confirmation
read -p "⚠️  Are you sure you want to delete workspace '$TFC_WORKSPACE'? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Deletion cancelled"
    exit 1
fi

# Delete the workspace
echo "🗑️  Deleting workspace '$TFC_WORKSPACE'..."
DELETE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --request DELETE \
    "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_CHECK")

HTTP_CODE=$(echo "$DELETE_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)

if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Workspace '$TFC_WORKSPACE' deleted successfully"
else
    echo "❌ Failed to delete workspace (HTTP $HTTP_CODE)"
    RESPONSE_BODY=$(echo "$DELETE_RESPONSE" | sed '/HTTP_CODE:/d')
    echo "$RESPONSE_BODY" | jq '.errors // .' 2>/dev/null || echo "$RESPONSE_BODY"
    exit 1
fi

echo ""
echo "✅ Cleanup complete!"
