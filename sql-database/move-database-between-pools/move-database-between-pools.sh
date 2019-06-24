#!/bin/bash

# set execution context (if necessary)
az account set --subscription <replace with your subscription name or id>

# Set the resource group name and location for your server
export resourceGroupName=myResourceGroup$RANDOM
export location=westus2

# Set an admin login and password for your database
export adminlogin=ServerAdmin
export password=P@ssw0rd-$RANDOM

# The logical server name has to be unique in the system
export servername=server$RANDOM

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

# Create a logical server in the resource group
az sql server create \
	--name $servername \
	--resource-group $resourceGroupName \
	--location $location \
	--admin-user $adminlogin \
	--admin-password $password

# Create two pools in the logical server
az sql elastic-pool create \
	--resource-group $resourceGroupName \
	--server $servername \
	--name myFirstPool \
	--edition GeneralPurpose \
	--family Gen4 \
	--capacity 1
az sql elastic-pool create \
	--resource-group $resourceGroupName \
	--server $servername \
	--name mySecondPool \
	--edition GeneralPurpose \
	--family Gen4 \
	--capacity 1

# Create a database in the first pool
az sql db create \
	--resource-group $resourceGroupName \
	--server $servername \
	--name mySampleDatabase \
	--elastic-pool myFirstPool

# Move the database to the second pool - create command updates the db if it exists
az sql db create \
	--resource-group $resourceGroupName \
	--server $servername \
	--name mySampleDatabase \
	--elastic-pool mySecondPool

# Move the database to standalone S0 service tier
az sql db create \
	--resource-group $resourceGroupName \
	--server $servername \
	--name mySampleDatabase \
	--service-objective S0

# Echo random password
echo $password