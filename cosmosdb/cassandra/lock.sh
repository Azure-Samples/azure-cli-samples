#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022
# Tested after running the "create.sh" script

# <FullScript>
# Resource lock operations for a Cassandra keyspace and table

# Subscription owner permissions required for this script

# Run this script after running
# "https://docs.microsoft.com/azure/cosmos-db/scripts/cli/cassandra/create#sample-script"

# Variable block
# Use values from prerequisite script or from your environment
# resourceGroup="your resource group name"
# account="your account name"
# keySpace="your keyspace name"
# table="your table name"

lockType="CanNotDelete" # CanNotDelete or ReadOnly
keySpaceParent="databaseAccounts/$account"
tableParent="databaseAccounts/$account/cassandraKeyspaces/$keySpace"
keySpaceLock="$keySpace-Lock"
tableLock="$table-Lock"

# Create a delete lock on keyspace
echo "Creating lock $lockType on $keySpaceLock"
az lock create --name $keySpaceLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/cassandraKeyspaces --lock-type $lockType --parent $keySpaceParent --resource $keySpace

# Create a delete lock on table
echo "Creating $lockType lock on $table"
az lock create --name $tableLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/tables --lock-type $lockType --parent $tableParent --resource $table

# List all locks on a Cosmos account
echo "Listing locks on $account"
az lock list --resource-group $resourceGroup --resource-name $account --namespace Microsoft.DocumentDB --resource-type databaseAccounts

# Delete lock on keyspace
echo "Deleting $keySpaceLock on $keySpace"
lockid=$(az lock show --name $keySpaceLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/cassandraKeyspaces --resource $keySpace --parent $keySpaceParent --output tsv --query id)
az lock delete --ids $lockid

# Delete lock on table
echo "Deleting $tableLock on $table"
lockid=$(az lock show --name $tableLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/tables --resource-name $table --parent $tableParent --output tsv --query id)
az lock delete --ids $lockid
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
