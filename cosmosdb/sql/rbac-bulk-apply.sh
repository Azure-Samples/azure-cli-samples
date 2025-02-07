#!/bin/bash

# <FullScript>
# This sample applies admin level Azure and Data RBAC roles in bulk to Azure Cosmos DB accounts 
# This script will apply this role for the current logged in user and for a
# a specified managed identity to every Cosmos account within a resource group.
# You can specify a single resource group with selected Cosmos DB accounts or
# you can process all accounts in every resource group in the subscription.

subscriptionId="your-subscription-id"

# Login to Azure if not already authenticated, select subscription
# This can be commented out if running in Azure Cloud Shell
az login
az account set -s $subscriptionId

# Get principal Id for an existing user-assigned managed identity you want to give access to
# You can also create one here then assign it in this script. Example, (az identity create -g "myResourceGroup" -n "myManagedIdentity")
# miPrincipalId=$(az identity show -g "myResourceGroup" -n "myManagedIdentity" --query id -o tsv)

# Capture the current user's principal Id and subscription Id
principalId=$(az ad signed-in-user show --query id -o tsv)


# Specify one or more resource groups and process all accounts within them
# Or specify just one resource group and only specific accounts within that one resource group
# Comment out to process all accounts in every resource group in the subscription
#resourceGroups=('resource group 1' 'resource group 2')

# Or you can process all accounts in every resource group in the subscription
if [ ${#resourceGroups[@]} -eq 0 ]; then
    resourceGroups=$(az group list --query "[].name" -o tsv)
fi


# Loop through every resource group
for resourceGroup in "${resourceGroups[@]}"; do
    echo "Processing resource group: $resourceGroup"

    # Get the role definition Id for the Doc DB Account Contributor role
    roleDefinitionId=$(az role definition list --name "DocumentDB Account Contributor" --query "[0].id" -o tsv)

    # Apply the Account Contributor role to the current user
    echo "Applying DocumentDB Account Contributor Azure RBAC role to current user and managed identity"
    az role assignment create --role $roleDefinitionId --assignee $principalId --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup --output none

    # Apply the Account Contributor role to the miPrincipalId if it is not null
    if [ ! -z "$miPrincipalId" ]; then
        az role assignment create --role $roleDefinitionId --assignee $miPrincipalId --scope /subscriptions/$subscriptionId/resourcegroups/$resourceGroup --output none
    fi

    # Limit to one or more Cosmos DB accounts within a specific resource group
    # Or comment out to process all accounts in the resource group
    # Only uncomment this if specifying a single resource group above
    #accounts=('cosmos account 1' 'cosmos account 2')
    
    # Or you can process all accounts in the resource group
    if [ ${#accounts[@]} -eq 0 ]; then
        processAllAccounts=true
        # Get the list of Cosmos DB accounts in this resource group
        mapfile -t accounts <<< "$(az cosmosdb list -g $resourceGroup --query "[].name" -o tsv)"
    fi

    # Loop through every Cosmos DB account in the resource group or array above
    for account in "${accounts[@]}"; do

        echo "Processing account: $account"

        # Trim potential leading/trailing whitespace from account
        account=$(echo "$account" | xargs)

        echo "Updating account: $account with RBAC Policy"
        echo "Please wait..."

        # Apply the RBAC policy to the Cosmos DB account
        az cosmosdb sql role assignment create \
        -n "Cosmos DB Built-in Data Contributor" \
        -g $resourceGroup \
        -a $account \
        -p $principalId \
        -s /"/" \
        --output none

        # Apply the RBAC policy to the miPrincipalId if it is not null
        if [ ! -z "$miPrincipalId" ]; then
            az cosmosdb sql role assignment create \
            -n "Cosmos DB Built-in Data Contributor" \
            -g $resourceGroup \
            -a $account \
            -p $miPrincipalId \
            -s /"/" \
            --output none
        fi

        echo "Update complete for account: $account"
        
    done
    
    # Reset the accounts array if processing all accounts in one or more resource groups
    if [ $processAllAccounts ]; then
        accounts=()
    fi

    echo "Resource group: $resourceGroup complete"

done

echo "All Done! Enjoy your new RBAC enabled Cosmos accounts!"

#</FullScript>
