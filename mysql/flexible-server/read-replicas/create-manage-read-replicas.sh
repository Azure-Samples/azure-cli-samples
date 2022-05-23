#!/bin/bash
# Passed validation in Cloud Shell on 2/9/2022

# <FullScript>
# Create and manage MySQL - Flexible Server read replicas

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
subscriptionId="$(az account show --query id -o tsv)"
location="East US"
resourceGroup="msdocs-mysql-rg-$randomIdentifier"
tag="monitor-and-scale-mysql"
server="msdocs-mysql-server-$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
ipAddress="None"
sku="Standard_D2ds_v4"
tier="GeneralPurpose"
storageSize="64"
replica="msdocs-replica-mysql-$randomIdentifier" # Substitute with preferred name for the replica server. 

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
az mysql flexible-server create --name $server --resource-group $resourceGroup --location "$location" --sku-name $sku --tier $tier --storage-size $storageSize --admin-user $login --admin-password $password --public-access $ipAddress

# Optional: Add firewall rule to connect from all Azure services
# To limit to a specific IP address or address range, change start-ip-address and end-ip-address
echo "Adding firewall for IP address range"
az mysql flexible-server firewall-rule create --name $server --resource-group $resourceGroup --rule-name AllowAzureIPs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Create Replica Server
echo "Creating $replica"
az mysql flexible-server replica create --replica-name $replica --source-server $server --resource-group $resourceGroup

# List all read replicas for the source server
echo "List replicas on $server"
az mysql flexible-server replica list --source-server $server --resource-group $resourceGroup

# Stop replication to a read replica and make it a read/write server.
echo "Stop replication to $replica"
az mysql flexible-server replica stop-replication --resource-group $resourceGroup --name $replica --yes
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
