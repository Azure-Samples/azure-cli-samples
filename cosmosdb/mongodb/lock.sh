#!/bin/bash
# Passed validation in Cloud Shell on 2/20/2022
# Tested after running the "create.sh" script

# <FullScript>
# Resource lock operations for a MongoDB API database and collection

# Subscription owner permissions required for this script

# Run this script after running
# "https://docs.microsoft.com/azure/cosmos-db/scripts/cli/mongodb/create#sample-script"

# Variable block
# Use values from prerequisite script or from your environment
# resourceGroup="your resource group name"
# account="your account name"
# database="your database name"
# collection="your collection name"

lockType='CanNotDelete' # CanNotDelete or ReadOnly
databaseParent="databaseAccounts/$account"
collectionParent="databaseAccounts/$account/mongodbDatabases/$database"
databaseLock="$database-Lock"
collectionLock="$collection-Lock"

# Create a delete lock on database
echo "Creating $lockType lock on $database"
az lock create --name $databaseLock \
--resource-group $resourceGroup \
--resource-type Microsoft.DocumentDB/mongodbDatabases --lock-type $lockType --parent $databaseParent --resource $database

# Create a delete lock on collection
echo "Creating $lockType lock on $collection"
az lock create --name $collectionLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/collections --lock-type $lockType --parent $collectionParent --resource $collection

# List all locks on a Cosmos account
echo "Listing locks on $account"
az lock list --resource-group $resourceGroup --resource-name $account --namespace Microsoft.DocumentDB --resource-type databaseAccounts

# Delete lock on database
echo "Deleting $databaseLock on $database"
lockid=$(az lock show --name $databaseLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/mongodbDatabases --resource $database --parent $databaseParent --output tsv --query id)
az lock delete --ids $lockid

# Delete lock on collection
echo "Deleting $collectionLock on $collection"
lockid=$(az lock show --name $collectionLock --resource-group $resourceGroup --resource-type Microsoft.DocumentDB/collections --resource-name $collection --parent $collectionParent --output tsv --query id)
az lock delete --ids $lockid
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
