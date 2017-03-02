#/bin/bash

# Variables
appName="webappwithredis$random"
storageName="webappredis$random"
location="westeurope"

# Create a Resource Group 
az group create --name myResourceGroup --location $location

# Create an App Service Plan
az appservice plan create --name WebAppWithRedisPlan --resource-group myResourceGroup --location $location

# Create a Web App
az appservice web create --name $appName --plan WebAppWithRedisPlan --resource-group myResourceGroup 

# Create a Redis Cache
redis=($(az redis create --name $appName --resource-group myResourceGroup --location $location --sku-capacity 0 --sku-family C --sku-name Basic --query [hostName,port,sslPort,enableNonSslPort,accessKeys.primaryKey] --output tsv))

# Should Connect over SSL
redisPort=[${redis[3]} -eq 'false'] && echo ${redis[1]} || echo ${redis[2]}

# Assign the connection string to an App Setting in the Web App
az appservice web config appsettings update --settings "REDIS_URL=${redis[0]}:${redisPort} REDIS_KEY=${redis[4]}" --name $appName --resource-group myResourceGroup