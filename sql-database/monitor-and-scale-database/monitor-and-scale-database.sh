#!/bin/bash

# set execution context (if necessary)
az account set --subscription <replace with your subscription name or id>

# Set the resource group name and location for your server
export resourceGroupName=myResourceGroup-$RANDOM
export location=westus2

# Set an admin login and password for your database
export adminlogin=ServerAdmin
export password=<EnterYourComplexPasswordHere>
# export password=P@ssw0rd-$RANDOM

# The logical server name has to be unique in the system
export servername=server-$RANDOM

# Create a resource group
az group create \
	--name $resourceGroupName \
	--location $location

# Create a server
az sql server create \
	--name $servername \
	--resource-group $resourceGroupName \
	--location $location \
	--admin-user $adminlogin \
	--admin-password $password

# Create a General Purpose Gen4 database with 1 vCore
az sql db create \
	--resource-group $resourceGroupName \
	--server $servername \
	--name mySampleDatabase \
	--edition GeneralPurpose \
	--family Gen4 \
	--capacity 1 

# Monitor database size
az sql db list-usages \
	--name mySampleDatabase \
	--resource-group $resourceGroupName \
	--server $servername

# Scale up database to 2 vCores (create command executes update if DB already exists)
az sql db create \
	--resource-group $resourceGroupName \
	--server $servername \
	--name mySampleDatabase \
	--edition GeneralPurpose \
	--family Gen4 \
	--capacity 2

# Echo random password
echo $password