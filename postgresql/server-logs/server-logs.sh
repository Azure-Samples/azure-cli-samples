#!/bin/bash
# Passed validation in Cloud Shell on 1/13/2022

# <FullScript>
# Enable and download server slow query logs of an Azure Database for PostgreSQL server

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-postgresql-rg-$randomIdentifier"
tag="server-logs-postgresql"
server="msdocs-postgresql-server-$randomIdentifier"
sku="GP_Gen5_2"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
configurationParameter="slow_query_log"
logValue="On"
durationStatementLog="durationStatementLog-$randomIdentifier"
logDuration="10000"
logFileList="logFileList"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a PostgreSQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az postgres server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name $sku

# List the configuration options for review
echo "Returning the configuration options on $server"
az postgres server configuration list --resource-group $resourceGroup --server $server

# Turn on statement level log
echo "Enable the statement level log"
az postgres server configuration set --name log_statement --resource-group $resourceGroup --server $server --value all

# Set log_min_duration_statement time to 10 sec
echo "Setting log_min_duration_statement to 10 sec"
az postgres server configuration set --name log_min_duration_statement --resource-group $resourceGroup --server $server --value 10000

# List the available log files
echo "Returning the list of available log files on $server"
az postgres server-logs list --resource-group $resourceGroup --server $server

# To download log file from Azure, direct the output of the previous comment to a text file 
# "> log_files_list.txt"
# Review the text file to find the server log file name for the desired timeframe
# Substitute the <log_file_name> in the script below with your server log file name
# Creates the log file in the current command line path
# az postgres server-logs download --name <log_file_name> $resourceGroup --server $server
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
