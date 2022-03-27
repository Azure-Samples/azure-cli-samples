#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

# <FullScript>
# Configure SQL Database auditing and Advanced Threat Protection

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="database-auditing-and-threat-detection"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
storage="msdocsazuresql$randomIdentifier"
notification="changeto@your.email;changeto@your.email"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --name $database --resource-group $resourceGroup --server $server --service-objective S0

echo "Creating $storage..."
az storage account create --name $storage --resource-group $resourceGroup --location "$location" --sku Standard_LRS

echo "Setting access policy on $storage..."
az sql db audit-policy update --name $database --resource-group $resourceGroup --server $server --state Enabled --bsts Enabled --storage-account $storage

echo "Setting threat detection policy on $storage..."
az sql db threat-policy update --email-account-admins Disabled --email-addresses $notification --name $database --resource-group $resourceGroup --server $server --state Enabled --storage-account $storage

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
