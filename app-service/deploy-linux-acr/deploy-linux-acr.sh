#/bin/bash

# Variables
appName="AppServiceLinuxDocker$random"
location="WestUS"
servicePrincipalPassword="Passw0rd123"
dockerContainerUser="cfowler/"
dockerHubContainerName="aspnetcoresample"
dockerContainerVersion=":0.1"

# Create a Resource Group
az group create --name myResourceGroup --location $location

# Create Azure Container Registry
acrid=$(az acr create --name $appName --resource-group myResourceGroup --location $location --admin-enabled true --query id --output tsv)

# Create a service principal
spid=$(az ad sp create-for-rbac --role Owner --password $servicePrincipalPassword --scopes $acrid --query appId --output tsv)

# Get Azure Container Registry URL
acrurl=$(az acr show --name $appName --resource-group myResourceGroup --query loginServer --output tsv)
acrUser=$(az acr show --name $appName --resource-group myResourceGroup --query username --output tsv)
acrPassword=$(az acr show --name $appName --resource-group myResourceGroup --query password --output tsv)

# Pull from Docker
docker login $acrurl -u $acrUser -p $acrPassword
docker pull $dockerContainerUser$dockerHubContainerName$dockerContainerVersion
docker push $dockerContainerUser$dockerHubContainerName

# Create an App Service Plan
az appservice plan create --name AppServiceLinuxDockerPlan --resource-group myResourceGroup --location $location --is-linux --sku S1

# Create a Web App
az appservice web create --name $appName --plan AppServiceLinuxDockerPlan --resource-group myResourceGroup

# Configure Web App with a Custom Docker Container from Docker Hub
az appservice web config container update --docker-registry-server-url $acrurl --docker-custom-image-name $dockerHubContainerName --docker-registry-server-user $spid --docker-registry-server-password $servicePrincipalPassword --name $appName --resource-group myResourceGroup