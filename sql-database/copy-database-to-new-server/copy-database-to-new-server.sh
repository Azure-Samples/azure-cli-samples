#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

# <FullScript>
# Copy a database in Azure SQL Database to a new server

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="copy-database-to-new-server"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
targetResourceGroup="msdocs-azuresql-targetrg-$randomIdentifier"
targetLocation="Central US"
targetServer="msdocs-azuresql-targetServer-$randomIdentifier"
targetDatabase="msdocs-azuresql-targetDatabase-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in location $location and $targetResourceGroup in $targetLocation..."
az group create --name $resourceGroup --location "$location" --tags $tag
az group create --name $targetResourceGroup --location "$targetLocation"

echo "Creating $server in $location and $targetServer in $targetLocation..."
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password
az sql server create --name $targetServer --resource-group $targetResourceGroup --location "$targetLocation" --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --name $database --resource-group $resourceGroup --server $server --service-objective S0

echo "Copying $database on $server to $targetDatabase on $targetServer..."
az sql db copy --dest-name $targetDatabase --dest-resource-group $targetResourceGroup --dest-server $targetServer --name $database --resource-group $resourceGroup --server $server

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $targetResourceGroup -y
# az group delete --name $resourceGroup -y
