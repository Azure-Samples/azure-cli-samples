#!/bin/bash

resourceGroup=amsResourceGroup
storageName=amsstorename
amsLocation=westus2
amsAccountName=amsmediaaccountname
amsSPName=mediaserviceprincipal
amsSPPassword=mediasppassword

# Create a resource resourceGroupName
az group create \
  --name $resourceGroup \
  --location $amsLocation

# Create an azure storage account
az storage account create \
  --name $storageName \
  --kind StorageV2 \
  --sku Standard_RAGRS \
  --location amsLocation \
  --resource-group $resourceGroup

# Create an azure media service account
az ams account create \
  --name $amsAccountName \
  --resource-group $resourceGroup \
  --storage-account $storageName \
  --location $amsLocation

# Create a service principal with password and configure its access to an Azure Media Services account.
az ams account sp create \
  --account-name $amsAccountName \
  --name $amsSPName \
  --resource-group $resourceGroup \
  --password $amsSPPassword \
  --role Owner
