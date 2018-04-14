#!/bin/bash

resourceGroup=myResourceGroup
storageName=amsstorename
amsAccountName=amsmediaaccountname
amsSPName=mediaserviceprincipal
amsSPPassword=mediasppassword

# Create a resource resourceGroupName
az group create \
  --name $resourceGroup \
  --location westus2

# Create an azure storage account
az storage account create \
  --name $storageName \
  --location westus2 \
  --resource-group $resourceGroup

# Create an azure media service account
az ams account create \
  --name $amsAccountName \
  --resource-group $resourceGroup \
  --storage-account $storageName \
  --location westus2

# Create a service principal with password and configure its access to an Azure Media Services account.
az ams account sp create \
  --account-name $amsAccountName \
  --name $amsSPName \
  --resource-group $resourceGroup \
  --password $amsSPPassword \
  --role Owner
