#!/bin/bash

RgName1="MyResourceGroup1"
RgName2="MyResourceGroup2"
Location1="westus"
Location2="eastus"

# The values of the variables below must be unique (replace with your own names).
WebApp="MyWebApp"
WebAppL1="MyWebAppL1"
WebAppL2="MyWebAppL2"

# Create a resource group in location one.
az group create \
  --name $RgName1 \
  --location $Location1

# Create a resource group in location two.
az group create \
  --name $RgName2 \
  --location $Location2

# Create a website deployed from GitHub in both regions (replace with your own GitHub URL).
gitrepo="https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git"

# Create a hosting plan and website and deploy it in location one (requires Standard 1 minimum SKU).
az appservice plan create \
  --name $WebAppL1 \
  --resource-group $RgName1 \
  --sku S1
az appservice web create \
  --name $WebAppL1 \
  --resource-group $RgName1 \
  --plan $WebAppL1
az appservice web source-control config \
  --name $WebAppL1 \
  --resource-group $RgName1 \
  --repo-url $gitrepo \
  --branch master \
  --manual-integration

# Create a hosting plan and website and deploy it in westus (requires Standard 1 minimum SKU).
az appservice plan create \
  --name $WebAppL2 \
  --resource-group $RgName2 \
  --sku S1
az appservice web create \
  --name $WebAppL2 \
  --resource-group $RgName2 \
  --plan $WebAppL2
az appservice web source-control config \
  --name $WebAppL2 \
  --resource-group $RgName2 \
  --repo-url $gitrepo \
  --branch master --manual-integration

# Create a Traffic Manager profile.
az network traffic-manager profile create \
  --name MyTrafficManagerProfile \
  --resource-group $RgName1 \
  --routing-method Priority \
  --unique-dns-name $WebApp

# Create an endpoint for the location one website deployment and set it as the priority target.
L1Id=$(az appservice web show \
  --resource-group $RgName1 \
  --name $WebAppL1 \
  --query id \
  --out tsv)
az network traffic-manager endpoint create \
  --name MyEndPoint1 \
  --profile-name MyTrafficManagerProfile \
  --resource-group $RgName1 \
  --type azureEndpoints \
  --priority 1 \
  --target-resource-id $L1Id

# Create an endpoint for the location two website deployment and set it as the secondary target.
L2Id=$(az appservice web show \
  --resource-group $RgName2 \
  --name $WebAppL2 \
  --query id --out tsv)
az network traffic-manager endpoint create \
  --name MyEndPoint2 \
  --profile-name MyTrafficManagerProfile \
  --resource-group $RgName1 \
  --type azureEndpoints \
  --priority 2 \
  --target-resource-id $L2Id
