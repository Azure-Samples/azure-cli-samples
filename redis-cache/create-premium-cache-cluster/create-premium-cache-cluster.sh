#/bin/bash

# Creates a Resource Group named contosoGroup, and creates a Premium Redis Cache with clustering in that group named contosoCache

# Create a Resource Group 
az group create --name contosoGroup --location eastus

# Create a Redis Cache
az redis create --name contosoCache --resource-group contosoGroup --location eastus --sku-capacity 1 --sku-family P --sku-name Premium --shard-count 2

