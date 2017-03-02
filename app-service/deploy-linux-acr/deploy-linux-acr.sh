#/bin/bash

# Variables
appName="AppServiceLinuxDocker$RANDOM"
location="westeurope"
dockerContainerUser="<replace-with-docker-user>"    
dockerHubContainerName="<replace-with-docker-container>"
dockerContainerVersion="latest"

# Create a Resource Group
az group create --name myResourceGroup --location $location

# Create Azure Container Registry
acrUrl=$(az acr create --name $appName --resource-group myResourceGroup --location $location --admin-enabled true --query loginServer --output tsv)
acrCreds=($(az acr credential show --name $appName --resource-group myResourceGroup --query [username,password] --output tsv))

# Pull from Docker
docker login ${acrUrl} -u ${acrCreds[0]} -p ${acrCreds[1]}
docker pull $dockerContainerUser/$dockerHubContainerName:$dockerContainerVersion
docker tag $dockerContainerUser/$dockerHubContainerName:$dockerContainerVersion ${acrUrl}/$dockerHubContainerName:$dockerContainerVersion
docker push ${acrUrl}/$dockerHubContainerName:$dockerContainerVersion

# Create an App Service Plan
az appservice plan create --name AppServiceLinuxDockerPlan --resource-group myResourceGroup --location $location --is-linux --sku S1

# Create a Web App
az appservice web create --name $appName --plan AppServiceLinuxDockerPlan --resource-group myResourceGroup

# Configure Web App with a Custom Docker Container from Docker Hub
az appservice web config container update --docker-registry-server-url http://${acrUrl} --docker-custom-image-name ${acrUrl}/$dockerHubContainerName:$dockerContainerVersion --docker-registry-server-user ${acrCreds[0]} --docker-registry-server-password ${acrCreds[1]} --name $appName --resource-group myResourceGroup