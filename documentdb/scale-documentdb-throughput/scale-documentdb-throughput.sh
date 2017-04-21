#!/bin/bash

# Set variables for the new account, database, and collection
resourceGroupName=docdbgetstarted
location="South Central US"
name=docdb-test
databaseName=docdb-test-database
collectionName=docdb-test-collection
originalThroughput=400 
newThroughput=700

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

# Create a DocumentDB account
az documentdb create \
	--name $name \
	--resource-group $resourceGroupName \
	--kind GlobalDocumentDB \
	--locations $location  \
	--max-interval 10 \
	--max-staleness-prefix 200

# Create a DocumentDB database 
az documentdb add-database \
	--resource-group $resourceGroupName \
	--name $name \
	--dbname $databaseName \

# Create a DocumentDB collection
az documentdb add-collection \
	--resource-group $resourceGroupName \
	--name $name \
	--dbname $databaseName \
	--collname $collectionName \
    --througput $originalThrougput

# Scale throughput
az documentdb update \
	--name $name \
    --resource-group $resourceGroupName \
    --collname $collectionName \
	--throughput $newThroughput
