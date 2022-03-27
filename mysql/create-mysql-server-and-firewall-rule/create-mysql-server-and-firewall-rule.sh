#!/bin/bash
# Passed validation in Cloud Shell on 2/9/2022

# <FullScript>
# Create a MySQL server and configure a firewall rule

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="create-mysql-server-and-firewall-rule"
server="msdocs-mysql-server-$randomIdentifier"
sku="GP_Gen5_2"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
# Specify appropriate IP address values for your environment
# to limit / allow access to the MySQL server
startIp=0.0.0.0
endIp=0.0.0.0

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a MySQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az mysql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name $sku

# Configure a firewall rule for the server 
echo "Configuring a firewall rule for $server for the IP address range of $startIp to $endIp"
az mysql server firewall-rule create --resource-group $resourceGroup --server $server --name AllowIps --start-ip-address $startIp --end-ip-address $endIp
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
