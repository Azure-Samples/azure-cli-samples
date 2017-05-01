#!/bin/bash

# Set variables for the new account, database, and collection
resourceGroupName=docdbgetstarted
location="South Central US"
name=docdb-test
databaseName=docdb-mongodb-database
collectionName=docdb-mongodb-collection

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

# Create a MongoDB API DocumentDB account
az documentdb create \
	--name $name \
	--resource-group $resourceGroupName \
	--kind MongoDB \
	--locations $location  \
	--max-interval 10 \
	--max-staleness-prefix 200

# Create a MongoDB API DocumentDB database 
az documentdb add-database \
	--resource-group $resourceGroupName \
	--name $name \
	--dbname $databaseName \
    --locations $location

# Create a MongoDB API DocumentDB collection
az documentdb add-collection \
	--resource-group $resourceGroupName \
	--name $name \
	--dbname $databaseName \
	--collname $collectionName 

# Get the connection string for MongoDB apps
az documentdb list-connection-strings \
    --name $name \
    --resource-group $resourceGroupName 
