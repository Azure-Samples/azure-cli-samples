#!/bin/bash
# Passed validation in Cloud Shell on 7/7/2022

# <FullScript>
# Azure Cosmos DB offers one free-tier account per subscription
# This script will find if you have a free-tier account and output 
# the name of the Cosmos DB account and its resource group 


# These can remain commented out if running in Azure Cloud Shell

#az login
#az account set -s {your subscription id}

isFound=0

# Iterate through all the resource groups in the subscription
for rg in $(az group list --query "[].name" --output tsv) 
do

	echo "Checking resource group: $rg"
	
	# Return the Cosmos DB account in the resource group marked as free tier
	ft=$(az cosmosdb list -g $rg --query "[?enableFreeTier].name" --output tsv)
	
	if [ ${#ft} -gt 0 ]; then
		
		echo "$ft is a free tier account in resource group: $rg"
		isFound=1
		break
	
	fi

done

if [ $isFound -eq 0 ]; then
	echo "No Free Tier accounts in subscription"
fi
# </FullScript>
