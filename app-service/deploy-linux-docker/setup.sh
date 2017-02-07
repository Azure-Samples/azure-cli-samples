#/bin/bash

random=$(python -c 'import uuid; print(str(uuid.uuid4())[0:8])')
resourceGroupName="myResourceGroup$random"
appName="AppServiceLinuxDocker$random"
location="WestUS"
dockerHubContainerPath="cfowler/aspnetcoresample:0.1"

az group create --name $resourceGroupName --location $location
az appservice plan create --name AppServiceLinuxDockerPlan --resource-group $resourceGroupName --location $location --is-linux --sku S1
az appservice web create --name $appName --plan AppServiceLinuxDockerPlan --resource-group $resourceGroupName
az appservice web config container update --docker-custom-image-name $dockerHubContainerPath --name $appName --resource-group $resourceGroupName