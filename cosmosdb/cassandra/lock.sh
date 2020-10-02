#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Resource lock operations for a Cassandra keyspace and table
#
#

resourceGroupName='myResourceGroup'
accountName='my-cosmos-account'
keyspaceName='keyspace1'
tableName='table1'

lockType='CanNotDelete' # CanNotDelete or ReadOnly
keyspaceParent="databaseAccounts/$accountName"
tableParent="databaseAccounts/$accountName/cassandraKeyspaces/$keyspaceName"
keyspaceLockName="$keyspaceName-Lock"
tableLockName="$tableName-Lock"


# Create a delete lock on keyspace
az lock create --name $keyspaceLockName \
    --resource-group $resourceGroupName \
    --resource-type Microsoft.DocumentDB/cassandraKeyspaces \
    --lock-type $lockType \
    --parent $keyspaceParent \
    --resource $keyspaceName

# Create a delete lock on table
az lock create --name $tableLockName \
    --resource-group $resourceGroupName \
    --resource-type Microsoft.DocumentDB/tables \
    --lock-type $lockType \
    --parent $tableParent \
    --resource $tableName

# List all locks on a Cosmos account
az lock list --resource-group $resourceGroupName \
    --resource-name $accountName \
    --namespace Microsoft.DocumentDB \
    --resource-type databaseAccounts

# Delete lock on keyspace
lockid=$(az lock show --name $keyspaceLockName \
        --resource-group $resourceGroupName \
        --resource-type Microsoft.DocumentDB/cassandraKeyspaces \
        --resource $keyspaceName --parent $keyspaceParent \
        --output tsv --query id)
az lock delete --ids $lockid

# Delete lock on table
lockid=$(az lock show --name $tableLockName \
        --resource-group $resourceGroupName \
        --resource-type Microsoft.DocumentDB/tables \
        --resource-name $tableName \
        --parent $tableParent \
        --output tsv --query id)
az lock delete --ids $lockid
