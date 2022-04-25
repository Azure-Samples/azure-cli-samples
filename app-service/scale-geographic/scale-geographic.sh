#/bin/bash
# Passed validation in Cloud Shell on 4/24/2022

# <FullScript>
# set -e # exit if error
# Monitor an App Service app with web server logs
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="scale geographic"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
trafficManagerDns="msdocs-dns-$randomIdentifier"
app1Name="msdocs-appServiceTM1-$randomIdentifier"
app2Name="msdocs-appServiceTM1-$randomIdentifier"
location1="WestUS"
location2="EastUS"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a Traffic Manager Profile
echo "Creating $trafficManagerDNS"
az network traffic-manager profile create --name $trafficManagerDNS-tmp --resource-group $resourceGroup --routing-method Performance --unique-dns-name $trafficManagerDNS

# Create App Service Plans in two Regions
az appservice plan create --name $app1Name-Plan --resource-group $resourceGroup --location $location1 --sku S1
az appservice plan create --name $app2Name-Plan --resource-group $resourceGroup --location $location2 --sku S1

# Add a Web App to each App Service Plan
site1=$(az webapp create --name $app1Name --plan $app1Name-Plan --resource-group $resourceGroup --query id --output tsv)
site2=$(az webapp create --name $app2Name --plan $app2Name-Plan --resource-group $resourceGroup --query id --output tsv)

# Assign each Web App as an Endpoint for high-availabilty
az network traffic-manager endpoint create -n $app1Name-$location1 --profile-name $trafficManagerDNS-tmp -g $resourceGroup --type azureEndpoints --target-resource-id $site1
az network traffic-manager endpoint create -n $app2Name-$location2 --profile-name $trafficManagerDNS-tmp -g $resourceGroup --type azureEndpoints --target-resource-id $site2
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
