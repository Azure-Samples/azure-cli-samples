#!/bin/bash
# Passed validation in Cloud Shell on 1/11/2022

# <FullScript>
# Change server configurations

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mariadb-rg-$randomIdentifier"
tag="change-server-cofigurations-mariadb"
server="msdocs-mariadb-server-$randomIdentifier"
sku="GP_Gen5_2"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a MariaDB server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az mariadb server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name $sku

# Display all available configurations with valid values of an Azure Database for MariaDB server
az mariadb server configuration list --resource-group $resourceGroup --server-name $server

# Set value of *innodb_lock_wait_timeout*
echo "Setting value of the innodb_lock_wait_timeout setting on $server"
az mariadb server configuration set --resource-group $resourceGroup --server-name $server --name innodb_lock_wait_timeout --value 120

# Check the value of *innodb_lock_wait_timeout*
echo "Checking the value of the innodb_lock_wait_timeout setting on $server"
az mariadb server configuration show --resource-group $resourceGroup --server-name $server --name innodb_lock_wait_timeout
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
