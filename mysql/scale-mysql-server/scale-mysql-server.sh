#!/bin/bash
# Passed validation in Cloud Shell on 2/9/2022

# <FullScript>
# Monitor and scale an Azure Database for MySQL server

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
subscriptionId="$(az account show --query id -o tsv)"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="scale-mysql-server"
server="msdocs-mysql-server-$randomIdentifier"
sku="GP_Gen5_2"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
scaleUpSku="GP_Gen5_4"
scaleDownSku="GP_Gen5_2"
storageSize="102400"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a MySQL server in the resource group
# Name of a server maps to DNS name and is thus required to be globally unique in Azure.
echo "Creating $server in $location..."
az mysql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password --sku-name $sku

# Monitor usage metrics - CPU
echo "Returning the CPU usage metrics for $server"
az monitor metrics list --resource "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DBforMySQL/servers/$server" --metric cpu_percent --interval PT1M

# Monitor usage metrics - Storage
echo "Returning the storage usage metrics for $server"
az monitor metrics list --resource "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.DBforMySQL/servers/$server" --metric storage_used --interval PT1M

# Scale up the server by provisionining more vCores within the same tier
echo "Scaling up $server by changing the SKU to $scaleUpSku"
az mysql server update --resource-group $resourceGroup --name $server --sku-name $scaleUpSku

# Scale down the server by provisioning fewer vCores within the same tier
echo "Scaling down $server by changing the SKU to $scaleDownSku"
az mysql server update --resource-group $resourceGroup --name $server --sku-name $scaleDownSku

# Scale up the server to provision a storage size of 10GB
# Storage size cannot be reduced
echo "Scaling up the storage size for $server to $storageSize"
az mysql server update --resource-group $resourceGroup --name $server --storage-size $storageSize
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
