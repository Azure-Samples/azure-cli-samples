#/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Connect an App Service app to an Azure Cache for Redis
#
# This sample script creates an Azure Cache for Redis 
# and an App Service app. It then links the Azure Cache
# for Redis to the app using app settings.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="connect-to-redis.sh" 
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service Plan
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup \
--location "$location"

# Create a Web App
echo "Creating $webapp"
az webapp create --name $webapp --plan $appServicePlan --resource-group $resourceGroup 

# Create a Redis Cache
redis=($(az redis create --name $webapp --resource-group $resourceGroup --location "$location" --vm-size C0 --sku Basic --query [hostName,sslPort] --output tsv))

# Get access key
key=$(az redis list-keys --name $webapp --resource-group $resourceGroup --query primaryKey --output tsv)

# Assign the connection string to an App Setting in the Web App
az webapp config appsettings set --name $webapp --resource-group $resourceGroup --settings "REDIS_URL=${redis[0]}" "REDIS_PORT=${redis[1]}" "REDIS_KEY=$key"
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
