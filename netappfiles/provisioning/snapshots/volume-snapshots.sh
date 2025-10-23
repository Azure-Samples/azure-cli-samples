#!/bin/bash
# Passed validation in Cloud Shell on 07/19/2025

# <FullScript>
# Manage volume snapshots

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-netappfiles-rg-$randomIdentifier"
tag="volume-snapshots-netappfiles"
netAppAccount="msdocs-netapp-account-$randomIdentifier"
capacityPool="msdocs-pool-$randomIdentifier"
vNet="msdocs-vnet-$randomIdentifier" 
subnet="msdocs-netapp-subnet-$randomIdentifier"
volume="msdocs-volume-$randomIdentifier"
snapshot="msdocs-snapshot-$randomIdentifier"
serviceLevel="Premium"
poolSize="4398046511104" # 4 TiB
volumeSize="107374182400" # 100 GiB
vnetAddressPrefix="10.0.0.0/16"
subnetAddressPrefix="10.0.1.0/24"

# Create resource group, vnet, NetApp account, pool, and volume (abbreviated)
echo "Setting up NetApp infrastructure..."
az group create --name $resourceGroup --location "$location" --tags $tag

az network vnet create --resource-group $resourceGroup --name $vNet --location "$location" --address-prefix $vnetAddressPrefix --subnet-name $subnet --subnet-prefix $subnetAddressPrefix
az network vnet subnet update --resource-group $resourceGroup --vnet-name $vNet --name $subnet --delegations Microsoft.NetApp/volumes

az netappfiles account create --resource-group $resourceGroup --location "$location" --account-name $netAppAccount
az netappfiles pool create --resource-group $resourceGroup --location "$location" --account-name $netAppAccount --pool-name $capacityPool --size $poolSize --service-level $serviceLevel
az netappfiles volume create --resource-group $resourceGroup --location "$location" --account-name $netAppAccount --pool-name $capacityPool --volume-name $volume --service-level $serviceLevel --usage-threshold $volumeSize --file-path $volume --vnet $vNet --subnet $subnet --protocol-types "NFSv3"

# Create a volume snapshot
echo "Creating snapshot $snapshot of volume $volume"
az netappfiles snapshot create \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --volume-name $volume \
    --snapshot-name $snapshot

# List snapshots for the volume
echo "Listing snapshots for volume $volume"
az netappfiles snapshot list \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --volume-name $volume \
    --query "[].{Name:name,Created:created,ProvisioningState:provisioningState}" \
    --output table

# Show snapshot details
echo "Displaying snapshot details"
az netappfiles snapshot show \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --volume-name $volume \
    --snapshot-name $snapshot

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
