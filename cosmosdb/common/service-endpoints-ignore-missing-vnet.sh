#!/bin/bash

# Create an Azure Cosmos Account with a service endpoint connected to a backend subnet
# that is not yet enabled for service endpoints.

# This sample demonstrates how to configure service endpoints for existing Cosmos account where
# the connected subnet is not yet configured for service endpoints.
# This sample will then configure the subnet for service endpoints.

# Generate a unique 10 character alphanumeric string to ensure unique resource names
uniqueId=$(env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 10 | head -n 1)

# Resource group and Cosmos account variables
resourceGroupName="Group-$uniqueId"
location='westus2'
accountName="cosmos-$uniqueId" #needs to be lower case

# Variables for a new Virtual Network with two subnets
vnetName='myVnet'
frontEnd='FrontEnd'
backEnd='BackEnd'

# Create a resource group
az group create -n $resourceGroupName -l $location

# Create a virtual network with a front-end subnet
az network vnet create \
    -n $vnetName \
    -g $resourceGroupName \
    --address-prefix 10.0.0.0/16 \
    --subnet-name $frontEnd \
    --subnet-prefix 10.0.1.0/24

# Create a back-end subnet but without specifying --service-endpoints Microsoft.AzureCosmosDB
az network vnet subnet create \
    -n $backEnd \
    -g $resourceGroupName \
    --address-prefix 10.0.2.0/24 \
    --vnet-name $vnetName

svcEndpoint=$(az network vnet subnet show -g $resourceGroupName -n $backEnd --vnet-name $vnetName --query 'id' -o tsv)

# Create a Cosmos DB account with default values
# Use appropriate values for --kind or --capabilities for other APIs
az cosmosdb create -n $accountName -g $resourceGroupName

# Add the virtual network rule but ignore the missing service endpoint on the subnet
az cosmosdb network-rule add \
    -n $accountName \
    -g $resourceGroupName \
    --virtual-network $vnetName \
    --subnet svcEndpoint \
    --ignore-missing-vnet-service-endpoint true

read -p'Press any key to configure the subnet for service endpoints'

az network vnet subnet update \
    -n $backEnd \
    -g $resourceGroupName \
    --vnet-name $vnetName \
    --service-endpoints Microsoft.AzureCosmosDB
