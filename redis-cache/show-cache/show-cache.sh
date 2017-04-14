#/bin/bash

# Retrieve the details for an Azure Redis Cache instance named contosoCache in the Resource Group contosoGroup
# This script shows details such as hostname, ports, and provisioning status
az redis show --name contosoCache --resource-group contosoGroup 