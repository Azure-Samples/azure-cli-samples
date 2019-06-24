#!/bin/bash

# set execution context (if necessary)
az account set --subscription <replace with your subscription name or id>

# Set the resource group name and location for your server
export resourceGroupName=myResourceGroup-$RANDOM
export location=westus2

# Set an admin login and password for your database
export adminlogin=ServerAdmin
export password=<EnterYourComplexPasswordHere1>
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

# Create a pool with 5 vCores and a max storage of 756 GB
az sql elastic-pool create \
	--resource-group $resourceGroupName \
	--server $servername \
	--name samplepool \
	--edition GeneralPurpose \
	--family Gen4 \
	--capacity 5 \
	--db-max-capacity 4 \
	--db-min-capacity 1 \
	--max-size 756GB

# Create two database in the pool
az sql db create \
	--resource-group $resourceGroupName \
	--server $servername \
	--name myFirstSampleDatabase \
	--elastic-pool samplepool

az sql db create \
	--resource-group $resourceGroupName \
	--server $servername \
	--name mySecondSampleDatabase \
	--elastic-pool samplepool

# Scale up to the pool to 10 vCores
az sql elastic-pool update \
	--resource-group $resourceGroupName \
	--server $servername \
	--name samplepool \
	--capacity 10 \
	--max-size 1536GB

# Echo random password
echo $password