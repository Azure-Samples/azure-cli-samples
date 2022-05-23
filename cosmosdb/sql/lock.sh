#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022
# Tested after running the "create.sh" script

# <FullScript>
# Resource lock operations for a SQL database and container

# Subscription owner permissions required for this script

# Run this script after running
# "https://docs.microsoft.com/azure/cosmos-db/scripts/cli/sql/create#sample-script"

# Variable block
# Use values from prerequisite script or from your environment
# resourceGroup="your resource group name"
# account="your account name"
# database="your database name"
# container="your container name"

lockType="CanNotDelete" # CanNotDelete or ReadOnly
databaseParent="databaseAccounts/$account"
containerParent="databaseAccounts/$account/sqlDatabases/$database"
databaseLock="$database-Lock"
containerLock="$container-Lock"

# Create a delete lock on database
echo "Creating $lockType lock on $database"
az lock create --name $databaseLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/sqlDatabases --lock-type $lockType --parent $databaseParent --resource $database

# Create a delete lock on container
echo "Creating $lockType lock on $container"
az lock create --name $containerLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/containers --lock-type $lockType --parent $containerParent --resource $container

# List all locks on a Cosmos account
echo "Listing locks on $account"
az lock list --resource-group $resourceGroup --resource-name $account --namespace Microsoft.DocumentDB --resource-type databaseAccounts

# Delete lock on database
echo "Deleting $databaseLock on $database"
lockid=$(az lock show --name $databaseLock     --resource-group $resourceGroup     --resource-type Microsoft.DocumentDB/sqlDatabases     --resource $database     --parent $databaseParent     --output tsv --query id)
az lock delete --ids $lockid

# Delete lock on container
echo "Deleting $containerLock on $container"
lockid=$(az lock show --name $containerLock     --resource-group $resourceGroup     --resource-type Microsoft.DocumentDB/containers     --resource-name $container     --parent $containerParent     --output tsv --query id)
az lock delete --ids $lockid
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
