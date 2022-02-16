#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Resource lock operations for a MongoDB API database and collection
#
#

resourceGroupName='myResourceGroup'
accountName='my-cosmos-account'
databaseName='myDatabase'
collectionName='myCollection'
tags="locks-mongodb-cosmosdb""
lockType='CanNotDelete' # CanNotDelete or ReadOnly
databaseParent="databaseAccounts/$account"
collectionParent="databaseAccounts/$account/mongodbDatabases/$database"
databaseLockName="$database-Lock"
collectionLockName="$collectionName-Lock"


# Create a delete lock on database
az lock create --name $databaseLockName \
    --resource-group $resourceGroup \
    --resource-type Microsoft.DocumentDB/mongodbDatabases \
    --lock-type $lockType \
    --parent $databaseParent \
    --resource $database

# Create a delete lock on collection
az lock create --name $collectionLockName \
    --resource-group $resourceGroup \
    --resource-type Microsoft.DocumentDB/collections \
    --lock-type $lockType \
    --parent $collectionParent \
    --resource $collectionName

# List all locks on a Cosmos account
az lock list --resource-group $resourceGroup \
    --resource-name $account \
    --namespace Microsoft.DocumentDB \
    --resource-type databaseAccounts

# Delete lock on database
lockid=$(az lock show --name $databaseLockName \
        --resource-group $resourceGroup \
        --resource-type Microsoft.DocumentDB/mongodbDatabases \
        --resource $database --parent $databaseParent \
        --output tsv --query id)
az lock delete --ids $lockid

# Delete lock on collection
lockid=$(az lock show --name $collectionLockName \
        --resource-group $resourceGroup \
        --resource-type Microsoft.DocumentDB/collections \
        --resource-name $collectionName \
        --parent $collectionParent \
        --output tsv --query id)
az lock delete --ids $lockid

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
