#/bin/bash

# Ensures unique id
random=$(python -c 'import uuid; print(str(uuid.uuid4())[0:8])')

# Variables
resourceGroupName="myResourceGroup$random"
app1Name="AppServiceTM1$random"
app2Name="AppServiceTM2$random"
location1="WestUS"
location2="EastUS"

# Create a Resource Group
az group create --name $resourceGroupName --location $location1

# Create a Traffic Manager Profile
az network traffic-manager profile create --name $resourceGroupName-tmp --resource-group $resourceGroupName --routing-method Performance --unique-dns-name $resourceGroupName

# Create App Service Plans in two Regions
az appservice plan create --name $app1Name-Plan --resource-group $resourceGroupName --location $location1 --sku S1
az appservice plan create --name $app2Name-Plan --resource-group $resourceGroupName --location $location2 --sku S1

# Add a Web App to each App Service Plan
site1=$(az appservice web create --name $app1Name --plan $app1Name-Plan --resource-group $resourceGroupName --query id --output tsv)
site2=$(az appservice web create --name $app2Name --plan $app2Name-Plan --resource-group $resourceGroupName --query id --output tsv)

# Assign each Web App as an Endpoint for high-availabilty
az network traffic-manager endpoint create -n $app1Name-$location1 --profile-name $resourceGroupName-tmp -g $resourceGroupName --type azureEndpoints --target-resource-id $site1
az network traffic-manager endpoint create -n $app2Name-$location2 --profile-name $resourceGroupName-tmp -g $resourceGroupName --type azureEndpoints --target-resource-id $site2