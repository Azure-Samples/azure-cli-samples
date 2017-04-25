#!/bin/bash

# Set an admin login and password for your database
export adminlogin=ServerAdmin
export password=ChangeYourAdminPassword1
# The logical server name has to be unique in the system
export servername=server-$RANDOM

# Create a resource group
az group create \
	--name myResourceGroup \
	--location westeurope 

# Create a logical server in the resource group
az sql server create \
	--name $servername \
	--resource-group myResourceGroup \
	--location westeurope \
	--admin-user $adminlogin \
	--admin-password $password

# Create two pools in the logical server
az sql elastic-pools create \
	--resource-group myResourceGroup \
	--location westeurope  \
	--server $servername \
	--name myFirstPool \
	--dtu 50 \
	--database-dtu-max 20
az sql elastic-pools create \
	--resource-group myResourceGroup \
	--location westeurope  \
	--server $servername \
	--name MySecondPool \
	--dtu 50 \
	--database-dtu-max 50

# Create a database in the first pool
az sql db create \
	--resource-group myResourceGroup \
	--server $servername \
	--name mySampleDatabase \
	--elastic-pool-name myFirstPool

# Move the database to the second pool - create command updates the db if it exists
az sql db create \
	--resource-group myResourceGroup \
	--server-name $servername \
	--name mySampleDatabase \
	--elastic-pool-name mySecondPool

# Move the database to standalone S1 performance level
az sql db create \
	--resource-group myResourceGroup \
	--server $servername \
	--name mySampleDatabase \
	--service-objective S1
