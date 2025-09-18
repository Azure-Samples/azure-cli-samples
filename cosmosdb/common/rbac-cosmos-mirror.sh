#!/usr/bin/env bash
set -euo pipefail

# Requires: Azure CLI installed and `az login` already completed.

# <FullScript>
# This sample creates and applies a custom RBAC role to enable Cosmos Mirroring for Fabric 
# This script will apply this role for the current logged in user
# This role allows reading metadata and analytics from the Cosmos DB account, which is necessary for Cosmos Mirroring.
# You can specify the Cosmos DB account, resource group, and subscription to target.

confirm_yes() {
  # prompt text, default 'no'
  local prompt="${1:-Continue?}"
  local reply
  read -r -p "$prompt [y/N]: " reply
  case "$reply" in
    [Yy]|[Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
  esac
}

# ---- Inputs ----
read -rp "Enter the Azure Subscription ID: " subscriptionId
read -rp "Enter the Resource Group name: " resourceGroup
read -rp "Enter the Cosmos DB account name: " accountName

# ---- Pre-flight checks ----
if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI ('az') not found. Please install Azure CLI and try again." >&2
  exit 1
fi

# Ensure logged in (attempt a read)
if ! az account show >/dev/null 2>&1; then
  echo "You're not logged in. Run 'az login' and try again." >&2
  exit 1
fi

# ---- Set subscription ----
echo "Setting Azure subscription to $subscriptionId..."
az account set --subscription "$subscriptionId" || { echo "Failed to set the subscription. Check the Subscription ID and your access." >&2; exit 1; }

# ---- Constants & Scope ----
roleName="Custom-CosmosDB-Metadata-Analytics-Reader"
scope="/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DocumentDB/databaseAccounts/$accountName"
jsonFile="Custom-CosmosDB-RBAC-for-Mirroring.json"
wroteJson="no"

# ---- Ensure role definition exists (idempotent) ----
echo "Checking for existing Cosmos DB SQL role definition '$roleName'..."
# Use JMESPath to return the role id (if present) as TSV
roleId=$(az cosmosdb sql role definition list \
  --account-name "$accountName" \
  --resource-group "$resourceGroup" \
  --query "[?roleName=='$roleName'].id | [0]" -o tsv 2>/dev/null || true)

if [ -z "${roleId:-}" ] || [ "$roleId" = "None" ] || [ "$roleId" = "null" ]; then
  # Create a new role definition id
  if command -v uuidgen >/dev/null 2>&1; then
    roleId=$(uuidgen)
  else
    roleId=$(python - <<'PY'
import uuid
print(uuid.uuid4())
PY
)
  fi

  echo "No existing role found. Preparing new role definition with Id $roleId..."

  jsonBody=$(cat <<EOF
{
  "Id": "$roleId",
  "RoleName": "$roleName",
  "Type": "CustomRole",
  "AssignableScopes": [
    "$scope"
  ],
  "Permissions": [
    {
      "DataActions": [
        "Microsoft.DocumentDB/databaseAccounts/readMetadata",
        "Microsoft.DocumentDB/databaseAccounts/readAnalytics"
      ],
      "NotDataActions": []
    }
  ]
}
EOF
)

  if confirm_yes "Write role definition JSON to '$jsonFile'?"; then
    printf '%s\n' "$jsonBody" > "$jsonFile"
    wroteJson="yes"
    echo "Wrote $jsonFile"
    az_body_arg="@${jsonFile}"
  else
    az_body_arg="$jsonBody"
  fi

  az cosmosdb sql role definition create \
    --account-name "$accountName" \
    --resource-group "$resourceGroup" \
    --body "$az_body_arg"

  if [ $? -ne 0 ]; then
    echo "Role definition creation failed." >&2
    exit 1
  fi

  echo "Created role definition '$roleName' ($roleId)."
else
  echo "Found existing role definition '$roleName' ($roleId)."

  # (Re)build JSON so it reflects the actual roleId and scope we’re using
  jsonBody=$(cat <<EOF
{
  "Id": "$roleId",
  "RoleName": "$roleName",
  "Type": "CustomRole",
  "AssignableScopes": [
    "$scope"
  ],
  "Permissions": [
    {
      "DataActions": [
        "Microsoft.DocumentDB/databaseAccounts/readMetadata",
        "Microsoft.DocumentDB/databaseAccounts/readAnalytics"
      ],
      "NotDataActions": []
    }
  ]
}
EOF
)

  if confirm_yes "Update local JSON file '$jsonFile' to reflect current scope/id?"; then
    printf '%s\n' "$jsonBody" > "$jsonFile"
    wroteJson="yes"
    echo "JSON file '$jsonFile' updated."
  else
    echo "Skipped writing JSON file."
  fi
fi

# ---- Assign to current signed-in user (idempotent) ----
echo "Retrieving signed-in user ObjectId..."
principalId=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)
if [ -z "${principalId:-}" ]; then
  echo "Could not determine the signed-in user automatically."
  read -rp "Enter the principal id (objectId) to assign the role to (leave empty to abort): " principalId
  if [ -z "${principalId:-}" ]; then
    echo "Aborting: no principal id provided." >&2
    exit 1
  fi
fi

echo "Current principal: $principalId"

echo "Checking for existing role assignment..."
existingAssignmentId=$(az cosmosdb sql role assignment list \
    --account-name "$accountName" \
    --resource-group "$resourceGroup" \
    --scope "$scope" \
    --query "[?principalId=='$principalId' && roleDefinitionId=='$roleId'] | [0].id" -o tsv 2>/dev/null || true)

if [ -n "${existingAssignmentId:-}" ] && [ "$existingAssignmentId" != "None" ] && [ "$existingAssignmentId" != "null" ]; then
  echo "Role assignment already exists (Assignment Id: $existingAssignmentId)."
else
  echo "Creating role assignment for principal $principalId..."
  az cosmosdb sql role assignment create \
    --account-name "$accountName" \
    --resource-group "$resourceGroup" \
    --role-definition-id "$roleId" \
    --principal-id "$principalId" \
    --scope "$scope"

  if [ $? -ne 0 ]; then
    echo "Role assignment failed." >&2
    exit 1
  fi
  echo "✅ Role assigned successfully."
fi

cat <<SUMMARY

Summary
-------
Subscription : $subscriptionId
ResourceGroup: $resourceGroup
Account      : $accountName
Scope        : $scope
Role Name    : $roleName
Role Id      : $roleId
Principal Id : $principalId
JSON File    : $jsonFile
JSON Written : $wroteJson
SUMMARY

# </FullScript>
