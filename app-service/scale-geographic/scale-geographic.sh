#/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Scale an App Service app worldwide with a high-availability architecture
#
# This sample script creates a resource group, two App Service plans, 
# two apps, a traffic manager profile, and two traffic manager endpoints.
# Once the exercise is complete, you have a high-available architecture, 
# which provides global availability of your app based on the lowest network latency.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="scale-geographic.sh"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
trafficManagerDns="msdocs-dns-$randomIdentifier"
app1Name="msdocs-appServiceTM1-$randomIdentifier"
app2Name="msdocs-appServiceTM2-$randomIdentifier"
location1="West US"
location2="East US"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a Traffic Manager Profile
echo "Creating $trafficManagerDNS"
az network traffic-manager profile create --name $trafficManagerDns-tmp --resource-group $resourceGroup --routing-method Performance --unique-dns-name $trafficManagerDns

# Create App Service Plans in two Regions
az appservice plan create --name $app1Name-Plan --resource-group $resourceGroup --location "$location1" --sku S1
az appservice plan create --name $app2Name-Plan --resource-group $resourceGroup --location "$location2" --sku S1

# Add a Web App to each App Service Plan
site1=$(az webapp create --name $app1Name --plan $app1Name-Plan --resource-group $resourceGroup --query id --output tsv)
site2=$(az webapp create --name $app2Name --plan $app2Name-Plan --resource-group $resourceGroup --query id --output tsv)

# Assign each Web App as an Endpoint for high-availabilty
az network traffic-manager endpoint create -n $app1Name-"$location1" --profile-name $trafficManagerDns-tmp -g $resourceGroup --type azureEndpoints --target-resource-id $site1
az network traffic-manager endpoint create -n $app2Name-"$location2" --profile-name $trafficManagerDns-tmp -g $resourceGroup --type azureEndpoints --target-resource-id $site2
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
