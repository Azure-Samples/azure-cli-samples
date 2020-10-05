#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Resource lock operations for a Gremlin database and graph
#
#

resourceGroupName='myResourceGroup'
accountName='my-cosmos-account'
databaseName='database1'
graphName='graph1'

lockType='CanNotDelete' # CanNotDelete or ReadOnly
databaseParent="databaseAccounts/$accountName"
graphParent="databaseAccounts/$accountName/gremlinDatabases/$databaseName"
databaseLockName="$databaseName-Lock"
graphLockName="$containerName-Lock"


# Create a delete lock on database
az lock create --name $databaseLockName \
    --resource-group $resourceGroupName \
    --resource-type Microsoft.DocumentDB/gremlinDatabases \
    --lock-type $lockType \
    --parent $databaseParent \
    --resource $databaseName

# Create a delete lock on graph
az lock create --name $graphLockName \
    --resource-group $resourceGroupName \
    --resource-type Microsoft.DocumentDB/graphs \
    --lock-type $lockType \
    --parent $graphParent \
    --resource $graphName

# List all locks on a Cosmos account
az lock list --resource-group $resourceGroupName \
    --resource-name $accountName \
    --namespace Microsoft.DocumentDB \
    --resource-type databaseAccounts

# Delete lock on database
lockid=$(az lock show --name $databaseLockName \
        --resource-group $resourceGroupName \
        --resource-type Microsoft.DocumentDB/gremlinDatabases \
        --resource $databaseName --parent $databaseParent \
        --output tsv --query id)
az lock delete --ids $lockid

# Delete lock on graph
lockid=$(az lock show --name $graphLockName \
        --resource-group $resourceGroupName \
        --resource-type Microsoft.DocumentDB/graphs \
        --resource-name $graphName --parent $graphParent \
        --output tsv --query id)
az lock delete --ids $lockid
