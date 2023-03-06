#/bin/bash
# Passed validation in Cloud Shell on 01/31/2023

# <FullScript>
# Create and manage a C0 Redis Cache

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-redis-cache-rg-$randomIdentifier"
tag="create-manage-cache"
cache="msdocs-redis-cache-$randomIdentifier"
sku="basic"
size="C0"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Basic C0 (256 MB) Redis Cache
echo "Creating $cache"
az redis create --name $cache --resource-group $resourceGroup --location "$location" --sku $sku --vm-size $size

# Get details of an Azure Cache for Redis
echo "Showing details of $cache"
az redis show --name $cache --resource-group $resourceGroup 

# Retrieve the hostname and ports for an Azure Redis Cache instance
redis=($(az redis show --name $cache --resource-group $resourceGroup --query [hostName,enableNonSslPort,port,sslPort] --output tsv))

# Retrieve the keys for an Azure Redis Cache instance
keys=($(az redis list-keys --name $cache --resource-group $resourceGroup --query [primaryKey,secondaryKey] --output tsv))

# Display the retrieved hostname, keys, and ports
echo "Hostname:" ${redis[0]}
echo "Non SSL Port:" ${redis[2]}
echo "Non SSL Port Enabled:" ${redis[1]}
echo "SSL Port:" ${redis[3]}
echo "Primary Key:" ${keys[0]}
echo "Secondary Key:" ${keys[1]}

# Delete a redis cache
echo "Deleting $cache"
az redis delete --name $resourceGroup --resource-group $resourceGroup -y
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y

