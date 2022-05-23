#!/bin/bash
# Passed validation in Cloud Shell on 2/28/2022

# <FullScript>
# Route traffic for high availability of applications

# Variables for Traffic Manager resources
let "randomIdentifier=$RANDOM*$RANDOM"
location1="East US"
location2="West Europe"
resourceGroup1="msdocs-tm-rg1-$randomIdentifier"
resourceGroup2="msdocs-tm-rg2-$randomIdentifier"
tag="direct-traffic-for-increased-application-availability"
webApp="msdocs-webapp-tm-$randomIdentifier"
webAppL1="msdocs-tm-webapp-L1-$randomIdentifier"
webAppL2="msdocs-tm-webapp-L2-$randomIdentifier"
trafficManagerProfile="msdocs-traffic-manager-profile-$randomIdentifier"

# Create a resource group in location one
echo "Creating $resourceGroup1 in $location1..."
az group create --name $resourceGroup1 --location "$location1" --tags $tag

# Create a resource group in location two
echo "Creating $resourceGroup2 in $location2..."
az group create --name $resourceGroup2 --location "$location2" --tags $tag

# Create a website deployed from GitHub in both regions (replace with your own GitHub URL).
gitrepo="https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git"

# Create a hosting plan and website and deploy it in location one (requires Standard 1 minimum SKU).
echo "Creating $webAppL1 app service plan"
az appservice plan create \
  --name $webAppL1 \
  --resource-group $resourceGroup1 \
  --sku S1

echo "Creating $webAppL1 web app"
az webapp create \
  --name $webAppL1 \
  --resource-group $resourceGroup1 \
  --plan $webAppL1

echo "Deploying $gitrepo to $webAppL1"
az webapp deployment source config \
  --name $webAppL1 \
  --resource-group $resourceGroup1 \
  --repo-url $gitrepo \
  --branch master \
  --manual-integration

# Create a hosting plan and website and deploy it in westus (requires Standard 1 minimum SKU).
echo "Creating $webAppL2 app service plan"
az appservice plan create \
  --name $webAppL2 \
  --resource-group $resourceGroup2 \
  --sku S1

echo "Creating $webAppL2 web app"
az webapp create \
  --name $webAppL2 \
  --resource-group $resourceGroup2 \
  --plan $webAppL2

echo "Deploying $gitrepo to $webAppL2"
az webapp deployment source config \
  --name $webAppL2 \
  --resource-group $resourceGroup2 \
  --repo-url $gitrepo \
  --branch master --manual-integration

# Create a Traffic Manager profile.
echo "Creating $trafficManagerProfile for $webApp"
az network traffic-manager profile create \
  --name $trafficManagerProfile \
  --resource-group $resourceGroup1 \
  --routing-method Priority \
  --unique-dns-name $webApp

# Create a traffic manager endpoint for the location one website deployment and set it as the priority target.
echo "Create traffic manager endpoint for $webAppL1"
l1Id=$(az webapp show \
  --resource-group $resourceGroup1 \
  --name $webAppL1 \
  --query id \
  --out tsv)
az network traffic-manager endpoint create \
  --name endPoint1 \
  --profile-name $trafficManagerProfile \
  --resource-group $resourceGroup1 \
  --type azureEndpoints \
  --priority 1 \
  --target-resource-id $l1Id

# Create a traffic manager endpoint for the location two website deployment and set it as the secondary target.
echo "Create traffic manager endpoint for $webAppL1"
l2Id=$(az webapp show \
  --resource-group $resourceGroup2 \
  --name $webAppL2 \
  --query id --out tsv)
az network traffic-manager endpoint create \
  --name endPoint2 \
  --profile-name $trafficManagerProfile \
  --resource-group $resourceGroup1 \
  --type azureEndpoints \
  --priority 2 \
  --target-resource-id $l2Id
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup1 -y
# az group delete --name $resourceGroup2 -y
