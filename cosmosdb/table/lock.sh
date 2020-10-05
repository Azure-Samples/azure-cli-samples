#!/bin/bash
# Reference: az cosmosdb | https://docs.microsoft.com/cli/azure/cosmosdb
# --------------------------------------------------
#
# Resource lock operations for a Table API table
#
#


resourceGroupName='myResourceGroup'
accountName='my-cosmos-account'
tableName='myTable'

lockType='CanNotDelete' # CanNotDelete or ReadOnly
tableParent="databaseAccounts/$accountName"
tableResourceType="$nameSpace/tables"
tableLockName='$tableName-Lock'


# Create a delete lock on table
az lock create --name $tableLockName \
    --resource-group $resourceGroupName \
    --resource-type $tableResourceType \
    --lock-type $lockType \
    --parent $tableParent \
    --resource $tableName

# List all locks on a Cosmos account
az lock list --resource-group $resourceGroupName \
    --resource-name $accountName \
    --namespace Microsoft.DocumentDB \
    --resource-type databaseAccounts

# Delete lock on table
lockid=$(az lock show --name $tableLockName \
        --resource-group $resourceGroupName \
        --resource-type $tableResourceType \
        --resource $tableName --parent $tableParent \
        --output tsv --query id)
az lock delete --ids $lockid
