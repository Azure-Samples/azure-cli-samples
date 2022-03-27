#/bin/# Passed validation in Cloud Shell on 3/11/2022

# <FullScript>
# Create and manage a premium P1 Redis Cache with clustering

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-redis-cache-rg-$randomIdentifier"
tag="create-manage-premium-cache-cluster"
cache="msdocs-redis-cache-$randomIdentifier"
sku="premium"
size="P1"
shardCount="2"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a Premium P1 (6 GB) Redis Cache with clustering enabled and 2 shards (for a total of 12 GB)
echo "Creating $cache"
az redis create --name $cache --resource-group $resourceGroup --location "$location" --sku $sku --vm-size $size --shard-count $shardCount

# Get details of an Azure Cache for Redis
echo "Showing details of $cache"
az redis show --name $cache --resource-group $resourceGroup 

# Retrieve the hostname and ports for an Azure Redis Cache instance
redis=($(az redis show --name $resourceGroup --resource-group $resourceGroup --query [hostName,enableNonSslPort,port,sslPort] --output tsv))

# Retrieve the keys for an Azure Redis Cache instance
keys=($(az redis list-keys --name contosoCache --resource-group contosoGroup --query [primaryKey,secondaryKey] --output tsv))

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


