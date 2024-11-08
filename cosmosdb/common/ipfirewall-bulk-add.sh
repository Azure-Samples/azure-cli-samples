#!/bin/bash

# Passed validation in Cloud Shell on 11/07/2024

# <FullScript>
# This sample adds IP Addresses in bulk to the IP Firewall Rules for an Azure Cosmos DB account.
# This script was primarily designed to add Azure Portal middleware IP addresses but can add any IP addresses.
# It also allows access from other Azure managed services without a fixed IP address (ie. Azure Functions) via
# the "0.0.0.0" IP Address providing access to your Cosmos accounts from these services.
# You can also enter custom IP Addresses and CIDR ranges. It can also add your current IP Address.
# By default this script will add all listed IP Addresses to every account in every
# resource group in the current subscription. You can also specify a single resource group
# and one or more Cosmos DB accounts within that resource group to process.

# These can remain commented out if running in Azure Cloud Shell
#az login
#az account set -s {your subscription id}

# Azure Public Cloud Portal IP Addresses. All is required. Some specific to database APIs
all=('13.91.105.215' '4.210.172.107' '13.88.56.148' '40.91.218.243')
mongoOnly=('20.245.81.54' '40.118.23.126' '40.80.152.199' '13.95.130.121')
cassandraOnly=('40.113.96.14' '104.42.11.145' '137.117.230.240' '168.61.72.237')

# Combine all the portal IP ranges
addIpAddresses=("${all[@]}" "${mongoOnly[@]}" "${cassandraOnly[@]}")

# Allow connections from Azure services within Azure datacenters
azureDataCenters=('0.0.0.0')
addIpAddresses+=("${azureDataCenters[@]}")

# Allow access custom IP Addresses and CIDR ranges
# Sample private IP Address and CIDR range
#custom=('10.0.0.1 10.10.0.0/16')
#addIpAddresses+=("${custom[@]}")

# Allow access from the current IP Address
currentIpAddress=$(curl -s ifconfig.me)
addIpAddresses+=("$currentIpAddress")

# print out how many IP addresses are in the list
echo "Total IP Addresses to process: ${#addIpAddresses[@]}"
echo "Adding the following IP Addresses from all Cosmos DB accounts: ${addIpAddresses[@]}"

# Convert the combined array into a comma-delimited string
IFS=',' # Set the Internal Field Separator to a comma
addIpAddresses="${addIpAddresses[*]}" # Join the array elements into a single string

# Get the list of resource groups in the current subscription
resourceGroups=$(az group list --query "[].name" -o tsv)

# Or you can specify a single resource group and process all accounts within it
# You can also limit to a specific number of accounts within a specific resource group
# resourceGroups=('myResourceGroup')


# Loop through every resource group in the subscription
for resourceGroup in "${resourceGroups[@]}"; do
    echo "Processing resource group: $resourceGroup"

    # Get the list of Cosmos DB accounts in this resource group
    mapfile -t accounts <<< "$(az cosmosdb list -g $resourceGroup --query "[].name" -o tsv)"

    # Limit to one or more Cosmos DB accounts within a specific resource group
    # Must specify a single resource group above to use this
    # accounts=('cosmos-account-1' 'cosmos-account-2')

    # Loop through every Cosmos DB account in the resource group or array above
    for account in "${accounts[@]}"; do

        echo "Processing account: $account"

        # Trim potential leading/trailing whitespace from account
        account=$(echo "$account" | xargs)

        echo "Updating account: $account with new IP Firewall Rules"
        echo "Please wait..."

        # This command will update the Cosmos DB account with the new IP Addresses
        # It can take up to 10 minutes to complete
        az cosmosdb update -g $resourceGroup -n $account --ip-range-filter $addIpAddresses --only-show-errors --output none
        
        echo "Update complete for account: $account"
        
    done

    echo "Resource group: $resourceGroup complete"

done

echo "All Done! Enjoy your new IP Firewall Rules!"

#</FullScript>