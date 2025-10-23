#!/bin/bash
# Passed validation in Cloud Shell on 07/19/2025

# <FullScript>
# Create NetApp volume

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-netappfiles-rg-$randomIdentifier"
tag="create-volume-netappfiles"
netAppAccount="msdocs-netapp-account-$randomIdentifier"
capacityPool="msdocs-pool-$randomIdentifier"
vNet="msdocs-vnet-$randomIdentifier"
subnet="msdocs-netapp-subnet-$randomIdentifier"
volume="msdocs-volume-$randomIdentifier"
serviceLevel="Premium"
poolSize="4398046511104" # 4 TiB
volumeSize="107374182400" # 100 GiB
vnetAddressPrefix="10.0.0.0/16"
subnetAddressPrefix="10.0.1.0/24"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a virtual network and subnet
echo "Creating $vNet with $subnet"
az network vnet create \
    --resource-group $resourceGroup \
    --name $vNet \
    --location "$location" \
    --address-prefix $vnetAddressPrefix \
    --subnet-name $subnet \
    --subnet-prefix $subnetAddressPrefix

# Delegate the subnet to Azure NetApp Files
echo "Delegating $subnet to Microsoft.NetApp/volumes"
az network vnet subnet update \
    --resource-group $resourceGroup \
    --vnet-name $vNet \
    --name $subnet \
    --delegations Microsoft.NetApp/volumes

# Create a NetApp account
echo "Creating $netAppAccount"
az netappfiles account create \
    --resource-group $resourceGroup \
    --location "$location" \
    --account-name $netAppAccount

# Create a capacity pool
echo "Creating $capacityPool"
az netappfiles pool create \
    --resource-group $resourceGroup \
    --location "$location" \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --size $poolSize \
    --service-level $serviceLevel

# Create a volume
echo "Creating $volume"
az netappfiles volume create \
    --resource-group $resourceGroup \
    --location "$location" \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --volume-name $volume \
    --service-level $serviceLevel \
    --usage-threshold $volumeSize \
    --file-path $volume \
    --vnet $vNet \
    --subnet $subnet \
    --protocol-types "NFSv3"

# Display volume information
echo "Volume $volume created successfully"
az netappfiles volume show \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --volume-name $volume \
    --query "{Name:name,FileSystemId:fileSystemId,ProvisioningState:provisioningState,MountTargets:mountTargets}" \
    --output table

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
