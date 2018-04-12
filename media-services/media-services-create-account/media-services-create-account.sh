#!/bin/bash

# Variables

resourceGroupName='amsResourceGroup'
location='westus2'
storageAccountName='juliakostorageaccountforams'
mediaServicesAccountName='juliakoamsaccountname'

az group create --name $resourceGroupName --location $location
az storage account create --name $storageAccountName --resource-group $resourceGroupName
az ams account create --name $mediaServicesAccountName --resource-group $resourceGroupName --storage-account $storageAccountName