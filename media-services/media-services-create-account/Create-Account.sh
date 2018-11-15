#!/bin/bash

# Update the following variables for your own settings:
resourceGroup=amsResourceGroup
storageName=amsstorename
amsAccountName=amsmediaaccountname
amsSPName=mediaserviceprincipal
amsSPPassword=mediasppassword

# Create a resource resourceGroupName
az group create \
  --name $resourceGroup \
  --location "westcentralus"

# Create an azure storage account, General Purpose v2, Standard RAGRS
az storage account create \
  --name $storageName \
  --kind StorageV2 \
  --sku Standard_RAGRS \
  --location "westcentralus" \
  --resource-group $resourceGroup

# Create an azure media service account
az ams account create \
  --name $amsAccountName \
  --resource-group $resourceGroup \
  --storage-account $storageName \
  --location "westcentralus"

# Create a service principal with password and configure its access to an Azure Media Services account.
az ams account sp create \
  --account-name $amsAccountName \
  --name $amsSPName \
  --password $amsSPPassword \
  --resource-group $resourceGroup \
  --role Owner \
  --xml \
  --years 2 \

echo "press  [ENTER]  to continue."
read continue
