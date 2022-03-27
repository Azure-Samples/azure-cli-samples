#!/bin/bash
# Passed validation in Cloud Shell on 1/13/2022

# <FullScript>
# List and update configurations of an Azure Database for PostgreSQL server

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-postgresql-rg-$randomIdentifier"
tag="change-server-cofigurations-postgresql"
server="msdocs-postgresql-server-$randomIdentifier"
sku="GP_Gen5_2"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a PostgreSQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az postgres server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name $sku

# Display all available configurations with valid values of an Azure Database for PostgreSQL server
az postgres server configuration list --resource-group $resourceGroup --server-name $server

# Set value of **log_retention_days**
echo "Setting value of the log_retention_days setting on $server"
az postgres server configuration set --resource-group $resourceGroup --server-name $server --name log_retention_days --value 7

# Check the value of **log_retention_days**
echo "Checking the value of the log_retention_days setting on $server"
az postgres server configuration show --resource-group $resourceGroup --server-name $server --name log_retention_days
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
