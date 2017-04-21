#!/bin/bash

# Set an admin login and password for your database
export adminlogin=ServerAdmin
export password=ChangeYourAdminPassword1
# the logical server name has to be unique in the system
export servername=server-$RANDOM

# Create a resource group
az group create \
	--name myResourceGroup \
	--location westeurope 

# Create a server
az sql server create \
	--name $servername \
	--resource-group myResourceGroup \
	--location westeurope \
	--admin-user $adminlogin \
	--admin-password $password

# Create a pool
az sql elastic-pools create \
	--resource-group myResourceGroup \
	--location westeurope  \
	--server $servername \
	--name samplepool \
	--dtu 50 \
	--database-dtu-max 20

# Create two database in the pool
az sql db create \
	--resource-group myResourceGroup \
	--server $servername \
	--name myFirstSampleDatabase \
	--elastic-pool-name samplepool
az sql db create \
	--resource-group myResourceGroup \
	--server $servername \
	--name mySecondSampleDatabase \
	--elastic-pool-name samplepool

# Scale up to the pool to 100 eDTU
az sql elastic-pools update \
	--resource-group myResourceGroup \
	--server $servername \
	--name samplepool \
	--set dtu=100
