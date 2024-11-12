#!/bin/bash

# Passed validation in Cloud Shell on 11/07/2024

# <FullScript>
# This sample removes IP Addresses in bulk from the IP Firewall Rules for an Azure Cosmos DB account.
# This script was primarily designed to remove Azure Portal middleware IP addresses but can remove any IP addresses.
# It also removes access from other Azure managed services without a fixed IP address (ie. Azure Functions) via
# the "0.0.0.0" IP Address restricting access to your Cosmos accounts from these services.
# You can also enter custom IP Addresses and CIDR ranges to remove as well.
# By default this script will add all listed IP Addresses to every account in every
# resource group in the current subscription. You can also specify a single resource group
# and one or more Cosmos DB accounts within that resource group to process.

# These can remain commented out if running in Azure Cloud Shell
#az login
#az account set -s {your subscription id}

# Portal IP Addresses. Various ranges are used for the Azure Portal, some specific to database APIs.
# The legacy Portal IP addresses are included here if you want to remove them in bulk from your Cosmos DB accounts
legacy=('139.217.8.252' '52.244.48.71' '104.42.195.92' '40.76.54.131' '52.176.6.30' '52.169.50.45' '52.187.184.26')
all=('13.91.105.215' '4.210.172.107' '13.88.56.148' '40.91.218.243')
mongoOnly=('20.245.81.54' '40.118.23.126' '40.80.152.199' '13.95.130.121')
cassandraOnly=('40.113.96.14' '104.42.11.145' '137.117.230.240' '168.61.72.237')

# Combine all the portal IP ranges. These can be safely combined. If they don't exist, they won't be removed.
removeIpAddresses=("${legacy[@]}" "${all[@]}" "${mongoOnly[@]}" "${cassandraOnly[@]}")

# Remove access from managed Azure Services from Azure datacenters
azureDataCenters=('0.0.0.0')
removeIpAddresses+=("$azureDataCenters")

# Remove custom IP Addresses and CIDR ranges from the IP Addresses
# Sample private IP Address and CIDR range
#custom=('10.0.0.1 10.10.0.0/16')
#removeIpAddresses+=("${custom[@]}")

# print out how many IP addresses are in the list
echo "Total IP Addresses to process: ${#removeIpAddresses[@]}"
echo "Removing the following IP Addresses from all Cosmos DB accounts: ${removeIpAddresses[@]}"

updatedIpAddresses=""
runUpdate=false

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


    # Loop through every Cosmos DB account in the resource group or array of specific accounts
    for account in "${accounts[@]}"; do

        echo "Processing account: $account"

        # Trim any leading/trailing whitespace from account
        account=$(echo "$account" | xargs)

        # Get the list of current IP Addresses for this Cosmos DB account
        # Assuming these are newline-separated, convert them into an array
        mapfile -t currentIpAddresses <<< "$(az cosmosdb show -g $resourceGroup -n $account --query "ipRules[].ipAddressOrRange" -o tsv)"

        echo "Account: $account, has ${#currentIpAddresses[@]} current IP Addresses"

        for currentIpAddress in "${currentIpAddresses[@]}"; do
            echo "Processing current IP Address: $currentIpAddress"
            matchFound=false
            
            # Trim potential leading/trailing whitespace from ipRule
            currentIpAddress=$(echo "$currentIpAddress" | xargs)
            
            # Check if the current IP Address is in the Remove IP Addresses array
            for removeIpAddress in "${removeIpAddresses[@]}"; do
                
                # Trim potential leading/trailing whitespace from ipRule
                removeIpAddress=$(echo "$removeIpAddress" | xargs)
                
                if [[ $currentIpAddress == $removeIpAddress ]]; then
                    
                    echo "Match found for IP Address: $currentIpAddress"
                    matchFound=true
                    # If any IPs match, run an update. If none do, don't update the account
                    runUpdate=true
                    break
                fi

            done

            if [[ $matchFound == false ]]; then
                # Current IP Address is not in the list of IP Addresses to remove. 
                # Preserve it in the updatedIpAddresses
                updatedIpAddresses+="$currentIpAddress,"
            fi
        done
        
        # Update the Cosmos DB account with the new list of IP Firewall Rules
        if [[ $runUpdate == true ]]; then

            # Trim the trailing comma and any carriage return characters from the CSV string
            updatedIpAddresses=$(echo "$updatedIpAddresses" | sed 's/,$//' | tr -d '\r')
            
            echo "Updating account: $account with existing IP Addresses not specified to be removed: $updatedIpAddresses"
            echo "Please wait..."

            # This command will update the Cosmos DB account with the new IP Addresses
            # It can take up to 10 minutes to complete
            az cosmosdb update -g $resourceGroup -n $account --ip-range-filter "$updatedIpAddresses" --only-show-errors --output none
            echo "Update complete for account: $account with new IP Addresses: $updatedIpAddresses"

        else
        
            echo "No update needed for account: $account"
        
        fi
        
        # Reset the variables for the next account
        updatedIpAddresses=""
        runUpdate=false

    done

    echo "Resource group: $resourceGroup complete"

done

echo "All Done! Enjoy your new IP Firewall Rules!"

#</FullScript>
