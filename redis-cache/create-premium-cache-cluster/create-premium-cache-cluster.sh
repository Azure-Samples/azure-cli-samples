#/bin/bash

# Creates a Resource Group named contosoGroup, and creates a Premium Redis Cache with clustering in that group named contosoCache

# Create a Resource Group 
az group create --name contosoGroup --location eastus

# Create a Premium P1 (6 GB) Redis Cache with clustering enabled and 2 shards (for a total of 12 GB)
az redis create --name contosoCache --resource-group contosoGroup --location eastus --vm-size P1 --sku Premium --shard-count 2
