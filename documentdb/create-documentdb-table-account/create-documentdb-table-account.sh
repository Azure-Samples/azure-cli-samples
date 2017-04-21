#!/bin/bash

# Set variables for the new account, database, and collection
resourceGroupName=docdbgetstarted
location="South Central US"
name=docdb-test
databaseName=docdb-mongodb-database
collectionName=docdb-mongodb-collection
throughput=400
zipcode=55104

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

# Create a Tables API DocumentDB account
az documentdb create \
	--name $name \
	--resource-group $resourceGroupName \
	--kind Tables \
	--locations $location  \
	--max-interval 10 \
	--max-staleness-prefix 200

# Create a Tables API DocumentDB database 
az documentdb add-database \
	--resource-group $resourceGroupName \
	--name $name \
	--dbname $databaseName 

# Create a Tables API DocumentDB collection
az documentdb add-collection \
	--resource-group $resourceGroupName \
	--name $name \
	--dbname $databaseName \
	--collname $collectionName \	
	--throughput $throughput \
	--partitionkey $zipcode