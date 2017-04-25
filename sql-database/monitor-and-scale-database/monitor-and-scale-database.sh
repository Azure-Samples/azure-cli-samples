#!/bin/bash

# Set an admin login and password for your database
export adminlogin=ServerAdmin
export password=ChangeYourAdminPassword1
# the logical server name has to be unique in the system
export servername=server-$RANDOM

# Create a resource group
az group create \
	--name myResourceGroup \
	-location westeurope 

# Create a server
az sql server create \
	--name $servername \
	--resource-group myResourceGroup \
	--location westeurope \
	--admin-user $adminlogin \
	--admin-password $password

# Create a database
az sql db create \
	--resource-group myResourceGroup \
	--server $servername \
	--name mySampleDatabase \
	--service-objective S0

# Monitor database size
az sql db show-usage \
	--name mySampleDatabase \
	--resource-group myResourceGroup \
	--name $servername

# Scale up database to S1 performance level (create command executes update if DB already exists)
az sql db create \
	--resource-group myResourceGroup \
	--server $servername \
	--name mySampleDatabase \
	--service-objective S1
