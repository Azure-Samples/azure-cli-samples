#!/bin/bash

# Create resource group
az group create --name myResourceGroup --location westeurope

# Create an azure storage account
az storage account create \
  --name myconsumptionstore \
  --location westeurope \
  --resource-group myResourceGroup \
  --sku Standard_LRS

# Create Function App
az functionapp create \
  --name myconsumptionfunc \
  --storage-account myconsumptionstore \
  --consumption-plan-location westeurope \
  --resource-group myResourceGroup