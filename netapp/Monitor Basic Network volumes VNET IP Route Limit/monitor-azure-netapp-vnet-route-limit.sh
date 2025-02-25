#!/bin/bash
# Replace the placeholders variable values (<your_resource_group>, <your_netapp_account_name>, <your_capacity_pool_name>, and <your_volume_name>) with the appropriate values for your Azure environment.
RESOURCE_GROUP="<your_resource_group>"
NETAPP_ACCOUNT_NAME="<your_netapp_account_name>"
CAPACITY_POOL_NAME="<your_capacity_pool_name>"
VOLUME_NAME="<your_volume_name>"

# Check NetApp volume details
echo "Checking NetApp volume details..."
VOLUME_DETAILS=$(az netappfiles volume show --resource-group $RESOURCE_GROUP --account-name $NETAPP_ACCOUNT_NAME --pool-name $CAPACITY_POOL_NAME --name $VOLUME_NAME)
VNET_NAME=$(echo $VOLUME_DETAILS | jq -r '.subnetId' | awk -F '/' '{print $9}')

echo "VNet associated with the NetApp volume: $VNET_NAME"

# Check number of IPs in the VNet
echo "Checking number of IPs in the VNet..."
VNET_DETAILS=$(az network vnet show --name $VNET_NAME --resource-group $RESOURCE_GROUP)
VNET_IP_COUNT=$(echo $VNET_DETAILS | jq '.addressSpace.addressPrefixes | length')

# Get peered VNets
PEERED_VNETS=$(az network vnet peering list --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --query "[].remoteVirtualNetwork.id" -o tsv)

TOTAL_IP_COUNT=$VNET_IP_COUNT

# Check number of IPs in each peered VNet
for PEERED_VNET_ID in $PEERED_VNETS; do
    PEERED_VNET_NAME=$(echo $PEERED_VNET_ID | awk -F '/' '{print $9}')
    PEERED_VNET_DETAILS=$(az network vnet show --name $PEERED_VNET_NAME --resource-group $RESOURCE_GROUP)
    PEERED_VNET_IP_COUNT=$(echo $PEERED_VNET_DETAILS | jq '.addressSpace.addressPrefixes | length')
    TOTAL_IP_COUNT=$((TOTAL_IP_COUNT + PEERED_VNET_IP_COUNT))
done

echo "Number of IPs in the VNet (including immediately peered VNets): $TOTAL_IP_COUNT"

# Check if the number of IPs exceeds the limit for Basic network features
if [ "$TOTAL_IP_COUNT" -gt 1000 ]; then
    echo "Warning: The number of IPs exceeds the limit for Basic network features (1000 IPs)."
else
    echo "The number of IPs is within the limit for Basic network features."
fi
