#!/bin/bash
# Passed validation in Cloud Shell on 2/9/2022

# <FullScript>
# Change server parameters for Azure Database for MySQL - Flexible Server

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="configure-audit-logs-mysql"
server="msdocs-mysql-server-$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
ipAddress="None"
# Specifying an IP address of 0.0.0.0 allows public access from any resources
# deployed within Azure to access your server. Setting it to "None" sets the server 
# in public access mode but does not create a firewall rule.
# For your public IP address, https://whatismyipaddress.com

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a MySQL Flexible server in the resource group
echo "Creating $server"
az mysql flexible-server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --public-access $ipAddress

# Optional: Add firewall rule to connect from all Azure services
# To limit to a specific IP address or address range, change start-ip-address and end-ip-address
echo "Adding firewall for IP address range"
az mysql flexible-server firewall-rule create --name $server --resource-group $resourceGroup --rule-name AllowAzureIPs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# List all MySQL - Flexible Server parameters with their values and parameter descriptions
echo "List parameters and values"
az mysql flexible-server parameter list --resource-group $resourceGroup --server-name $server

# Set value of max_connections parameter
echo "Set maximum connections"
az mysql flexible-server parameter set --resource-group $resourceGroup --server-name $server --name max_connections --value 250

# Check value of max_connections paramater
echo "Check maximum connections"
az mysql flexible-server parameter show --resource-group $resourceGroup --server-name $server --name max_connections

# Set value of max_connections parameter back to default
echo "Set maximum connnections to default"
az mysql flexible-server parameter set --resource-group $resourceGroup --server-name $server --name max_connections 

# Set global level time zone
echo "Set time zone"
az mysql flexible-server parameter set --resource-group $resourceGroup --server-name $server --name time_zone --value "+02:00"

# Check global level time zone
echo "Check time zone"
az mysql flexible-server parameter show --resource-group $resourceGroup --server-name $server --name time_zone
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
