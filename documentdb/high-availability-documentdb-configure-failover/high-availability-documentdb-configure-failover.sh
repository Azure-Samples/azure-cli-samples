#!/bin/bash

# Configure failover priorities 
az documentdb update \
	--name docdb-test \
	--resource-group myResourceGroup \
	--locations "East US"=2 "West US"=1 "South Central US"=0  