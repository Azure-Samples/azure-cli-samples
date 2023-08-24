#!/bin/bash
# Passed validation in Cloud Shell on 2/9/2022

# <FullScript>
# Create a server, perform restart / start / stop operations

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="restart-start-stop-mysql"
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

# Create a MySQL Flexible Server in the resource group
echo "Creating $server"
az mysql flexible-server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --public-access $ipAddress

# Optional: Add firewall rule to connect from all Azure services
# To limit to a specific IP address or address range, change start-ip-address and end-ip-address
echo "Adding firewall for IP address range"
az mysql flexible-server firewall-rule create --name $server --resource-group $resourceGroup --rule-name AllowAzureIPs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Stop the running server
echo "Stopping $server"
az mysql flexible-server stop --resource-group $resourceGroup --name $server

# Start the stopped server
echo "Starting $server"
az mysql flexible-server start --resource-group $resourceGroup --name $server

# Restart the server
echo "Restarting $server"
az mysql flexible-server restart --resource-group $resourceGroup --name $server
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
