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
acrValues=$(az acr create --name $appName --resource-group myResourceGroup --location $location --admin-enabled true --query "[loginServer,username,password]" --output tsv | cut -f1234)

# Pull from Docker
docker login ${acrValue[0]} -u ${acrValue[1]} -p ${acrValue[2]}
docker pull $dockerContainerUser/$dockerHubContainerName:$dockerContainerVersion
docker tag $dockerContainerUser/$dockerHubContainerName:$dockerContainerVersion ${acrValue[0]}/$dockerHubContainerName:$dockerContainerVersion
docker push ${acrValue[0]}/$dockerHubContainerName:$dockerContainerVersion

# Create an App Service Plan
az appservice plan create --name AppServiceLinuxDockerPlan --resource-group myResourceGroup --location $location --is-linux --sku S1

# Create a Web App
az appservice web create --name $appName --plan AppServiceLinuxDockerPlan --resource-group myResourceGroup

# Configure Web App with a Custom Docker Container from Docker Hub
az appservice web config container update --docker-registry-server-url http://${acrValue[0]} --docker-custom-image-name ${acrValue[0]}/$dockerHubContainerName:$dockerContainerVersion --docker-registry-server-user ${acrValue[1]} --docker-registry-server-password ${acrValue[2]} --name $appName --resource-group myResourceGroup