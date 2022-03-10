#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022
# Tested after running the "create.sh" script

# <FullScript>
# Resource lock operations for a Gremlin database and graph

# Subscription owner permissions required for this script

# Run this script after running
# "https://docs.microsoft.com/azure/cosmos-db/scripts/cli/gremln/create#sample-script"

# Variable block
# Use values from prerequisite script or from your environment
# resourceGroup="your resource group name"
# account="your account name"
# database="your database name"
# container="your container name"
# graph="your graph name"

lockType="CanNotDelete" # CanNotDelete or ReadOnly
databaseParent="databaseAccounts/$account"
graphParent="databaseAccounts/$account/gremlinDatabases/$database"
databaseLock="$database-Lock"
graphLock="$graph-Lock"

# Create a delete lock on database
echo "Creating $lockType lock on $database"
az lock create --name $databaseLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/gremlinDatabases --lock-type $lockType --parent $databaseParent --resource $database

# Create a delete lock on graph
echo "Creating $lockType lock on $graph"
az lock create --name $graphLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/graphs --lock-type $lockType --parent $graphParent --resource $graph

# List all locks on a Cosmos account
echo "Listing locks on $account"
az lock list --resource-group $resourceGroup --resource-name $account --namespace Microsoft.DocumentDB --resource-type databaseAccounts

# Delete lock on database
echo "Deleting $databaseLock on $database"
lockid=$(az lock show --name $databaseLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/gremlinDatabases --resource $database --parent $databaseParent --output tsv --query id)
az lock delete --ids $lockid

# Delete lock on graph
echo "Deleting $graphLock on $graph"
lockid=$(az lock show --name $graphLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/graphs --resource-name $graph --parent $graphParent --output tsv --query id)
az lock delete --ids $lockid
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
