#!/bin/bash

# Tested on February 7, 2025, with Azure CLI version 2.68.0

# <FullScript>
# This sample script is designed to help users migrate from key-based to Entra Id authentication for their
# Cosmos DB accounts by assigning RBAC roles to both your Entra Id as well as a new user assigned managed identity
# for you to apply as the "Identity" for any services within a resource group that contains a Cosmos DB account.

# This script can be run as-is and it will process every Cosmos account within every resource group.
# Or you can specify a single resource group and it will process every Cosmos account within it, or selected accounts.

subscriptionId="your-subscription-id"

# Login to Azure if not already authenticated, select subscription
# This can be commented out if running in Azure Cloud Shell
#az login
az account set -s $subscriptionId

# Capture the current user's Id
principalId=$(az ad signed-in-user show --query id -o tsv)


# Specify one or more resource groups and process all accounts within them
# Or specify just one resource group and only specific accounts within that one resource group
# Comment out to process all accounts in every resource group in the subscription
#resourceGroups=('resource group 1' 'resource group 2')

# Or you can process all resource groups and all acconts in the subscription
if [ ${#resourceGroups[@]} -eq 0 ]; then
    resourceGroups=$(az group list --query "[].name" -o tsv)
fi


# Loop through every resource group
for resourceGroup in "${resourceGroups[@]}"; do
    echo "Processing resource group: $resourceGroup"

    # Deployed services need their own identity to access Cosmos. 
    # Managed identities tend to be workload specific so we will 
    # create a new user assigned managed identity for each resource group.
    uaManagedIdentity="$resourceGroup-mi"
    az identity create -g $resourceGroup -n $uaManagedIdentity --output none
    miPrincipalId=$(az identity show -g $resourceGroup -n $uaManagedIdentity --query principalId -o tsv)
    echo "Managed Identity created: $uaManagedIdentity"


    # Get the role definition Id for the Document DB Account Contributor role (Azure RBAC)
    roleDefinitionId=$(az role definition list --name "DocumentDB Account Contributor" --query "[0].id" -o tsv)

    # Apply the Account Contributor role to you, the current user
    echo "Applying DocumentDB Account Contributor role to current user"
    az role assignment create --role $roleDefinitionId --assignee-object-id $principalId --assignee-principal-type "User" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup --output none

    # Apply the Account Contributor role to the user assigned managed identity if it is not null
    if [ ! -z "$miPrincipalId" ]; then
        echo "Applying DocumentDB Account Contributor role to the managed identity"
        az role assignment create --role $roleDefinitionId --assignee-object-id $miPrincipalId --assignee-principal-type "ServicePrincipal" --scope /subscriptions/$subscriptionId/resourcegroups/$resourceGroup --output none
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
    echo "Locate this user assigned managed identity: $uaManagedIdentity, in resource group: $resourceGroup and make it the identity for any services accessing Cosmos"

done

echo "All Done! Enjoy your new RBAC enabled Cosmos accounts!"

#</FullScript>

