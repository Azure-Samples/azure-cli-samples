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

lockType='CanNotDelete' # CanNotDelete or ReadOnly
databaseParent="databaseAccounts/$accountName"
collectionParent="databaseAccounts/$accountName/mongodbDatabases/$databaseName"
databaseLockName="$databaseName-Lock"
collectionLockName="$collectionName-Lock"


# Create a delete lock on database
az lock create --name $databaseLockName \
    --resource-group $resourceGroupName \
    --resource-type Microsoft.DocumentDB/mongodbDatabases \
    --lock-type $lockType \
    --parent $databaseParent \
    --resource $databaseName

# Create a delete lock on collection
az lock create --name $collectionLockName \
    --resource-group $resourceGroupName \
    --resource-type Microsoft.DocumentDB/collections \
    --lock-type $lockType \
    --parent $collectionParent \
    --resource $collectionName

# List all locks on a Cosmos account
az lock list --resource-group $resourceGroupName \
    --resource-name $accountName \
    --namespace Microsoft.DocumentDB \
    --resource-type databaseAccounts

# Delete lock on database
lockid=$(az lock show --name $databaseLockName \
        --resource-group $resourceGroupName \
        --resource-type Microsoft.DocumentDB/mongodbDatabases \
        --resource $databaseName --parent $databaseParent \
        --output tsv --query id)
az lock delete --ids $lockid

# Delete lock on collection
lockid=$(az lock show --name $collectionLockName \
        --resource-group $resourceGroupName \
        --resource-type Microsoft.DocumentDB/collections \
        --resource-name $collectionName \
        --parent $collectionParent \
        --output tsv --query id)
az lock delete --ids $lockid
