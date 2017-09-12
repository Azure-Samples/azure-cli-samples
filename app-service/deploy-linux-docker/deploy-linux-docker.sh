#/bin/bash

# Variables
appName="AppServiceLinuxDocker$random"
location="WestUS"
dockerHubContainerPath="<replace-with-docker-container-path>" #format: <username>/<container-or-image>:<tag>

# Create a Resource Group
az group create --name myResourceGroup --location $location

# Create an App Service Plan
az appservice plan create --name AppServiceLinuxDockerPlan --resource-group myResourceGroup --location $location --is-linux --sku S1

# Create a Web App
az webapp create --name $appName --plan AppServiceLinuxDockerPlan --resource-group myResourceGroup

# Configure Web App with a Custom Docker Container from Docker Hub
az webapp config container set --docker-custom-image-name $dockerHubContainerPath --name $appName --resource-group myResourceGroup

# Copy the result of the following command into a browser to see the web app.
echo http://$appName.azurewebsites.net
