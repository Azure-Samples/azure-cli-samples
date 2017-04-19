#!/bin/bash

# Replicate DocumentDB in multipe regions 
az documentdb update \
	--name docdb-test \
	--resource-group myResourceGroup \
	--locations "East US"=0 "West US"=1 "South Central US"=2  

# Modify regional failover priorities 
az documentdb update \
	--name docdb-test \
	--resource-group myResourceGroup \
	--locations "East US"=2 "West US"=1 "South Central US"=0  


