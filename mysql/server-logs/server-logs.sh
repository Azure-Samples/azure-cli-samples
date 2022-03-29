#!/bin/bash
# Passed validation in Cloud Shell on 2/9/2022

# <FullScript>
# Enable and download server slow query logs of an Azure Database for MySQL server

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="server-logs-mysql"
server="msdocs-mysql-server-$randomIdentifier"
sku="GP_Gen5_2"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
configurationParameter="slow_query_log"
logValue="On"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a MySQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az mysql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name $sku

# List the configuration options for review
echo "Returning the configuration options on $server"
az mysql server configuration list --resource-group $resourceGroup --server $server

# Show the value of the slow_query_log server configuration parameter
echo "Returning the value of the slow_query_log server configuration parameter on $server"
az mysql server configuration show --name $configurationParameter --resource-group $resourceGroup --server $server

# Enable the slow_query_log 
echo "Enabling the slow_query_log on $server"
az mysql server configuration set --name $configurationParameter --resource-group $resourceGroup --server $server --value $logValue

# List the available log files
echo "Returning the list of available log files on $server"
az mysql server-logs list --resource-group $resourceGroup --server $server

# To download log file from Azure, direct the output of the previous comment to a text file 
# "> log_files_list.txt"
# Review the text file to find the server log file name for the desired timeframe
# Substitute the <log_file_name> in the script below with your server log file name
# Creates the log file in the current command line path
# az mysql server-logs download --name <log_file_name> $resourceGroup --server $server
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
