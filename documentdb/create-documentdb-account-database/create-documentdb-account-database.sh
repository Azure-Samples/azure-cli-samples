#!/bin/bash

# Create a resource group
az group create \
	--name myResourceGroup \
	--location "East US"

# Create a DocumentDB account
az documentdb create \
	--name docdb-test \
	--resource-group myResourceGroup \
	--ip-range-filter "13.91.6.132,13.91.6.1/24" \
	--kind GlobalDocumentDB \
	--locations "East US"=0 "West US"=1 "South Central US"=2  \
	--max-interval 10
	--max-staleness-prefix 200

# Create a DocumentDB database 
az documentdb create \
	--resource-group myResourceGroup \
	--server docdb-test \
	--dbname mysampledatabase \
    --locations "East US"

# Create a DocumentDB collection
az documentdb create \
	--resource-group myResourceGroup \
	--server docdb-test \
	--collname mysamplecollection \
    --locations "East US"
