#!/bin/bash
# Passed validation in Cloud Shell on 2/9/2022

# <FullScript>
# Configure slow query logs on Azure Database for MySQL - Flexible Server

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="slow-query-logs-mysql"
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

# Enable slow query logs
echo "Enabling slow query logs"
az mysql flexible-server parameter set --name slow_query_log --resource-group $resourceGroup --server-name $server --value ON

# Set long_query_time time to 15 seconds
# This setting will log all queries executing for more than 15 sec. Please adjust this threshold based on your definition for slow queries
echo "Setting long query time to 15 seconds"
az mysql flexible-server parameter set --name long_query_time --resource-group $resourceGroup --server $server --value 15

# Allow slow administrative statements (ex. ALTER_TABLE, ANALYZE_TABLE) to be logged.
echo "Allow logging of slow administrative statements"
az mysql flexible-server parameter set --resource-group $resourceGroup --server-name $server --name log_slow_admin_statements --value ON
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
