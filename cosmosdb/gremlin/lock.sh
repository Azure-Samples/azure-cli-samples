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
tags="lock-gremlin-cosmosdb"
lockType='CanNotDelete' # CanNotDelete or ReadOnly
databaseParent="databaseAccounts/$account"
graphParent="databaseAccounts/$account/gremlinDatabases/$database"
databaseLockName="$database-Lock"
graphLockName="$containerName-Lock"


# Create a delete lock on database
az lock create --name $databaseLockName --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/gremlinDatabases --lock-type $lockType --parent $databaseParent --resource $database

# Create a delete lock on graph
az lock create --name $graphLockName --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/graphs --lock-type $lockType --parent $graphParent --resource $graphName

# List all locks on a Cosmos account
az lock list --resource-group $resourceGroup --resource-name $account --namespace Microsoft.DocumentDB --resource-type databaseAccounts

# Delete lock on database
lockid=$(az lock show --name $databaseLockName     --resource-group $resourceGroup     --resource-type Microsoft.DocumentDB/gremlinDatabases     --resource $database --parent $databaseParent     --output tsv --query id)
az lock delete --ids $lockid

# Delete lock on graph
lockid=$(az lock show --name $graphLockName     --resource-group $resourceGroup     --resource-type Microsoft.DocumentDB/graphs     --resource-name $graphName --parent $graphParent     --output tsv --query id)
az lock delete --ids $lockid

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
