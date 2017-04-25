#/bin/bash

# Creates a Resource Group named contosoGroup, and creates a Redis Cache in that group named contosoCache

# Create a Resource Group 
az group create --name contosoGroup --location eastus

# Create a Redis Cache
az redis create --name contosoCache --resource-group contosoGroup --location eastus --sku-capacity 0 --sku-family C --sku-name Basic

