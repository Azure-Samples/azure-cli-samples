#!/bin/bash
# Azure VMware Solution (AVS) with Azure NetApp Files Datastores - Complete Setup
# This script provisions ANF volumes optimized for AVS datastores

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="avs-anf-datastores-rg-$randomIdentifier"
tag="avs-anf-datastores"

# ANF Configuration for AVS
netAppAccount="avs-anf-account-$randomIdentifier"
capacityPool="avs-datastore-pool-$randomIdentifier"
serviceLevel="Ultra"  # Ultra performance for AVS workloads
poolSize="4398046511104" # 4 TiB minimum for AVS

# AVS Datastore Volume Configuration
datastoreVolume="avs-datastore-volume-$randomIdentifier"
volumeSize="1099511627776"  # 1 TiB per datastore
protocolTypes="NFSv3"  # AVS requires NFSv3

# Network Configuration for AVS
vnetName="avs-anf-vnet-$randomIdentifier"
anfSubnet="anf-subnet"
avsSubnet="avs-subnet"
vnetAddressPrefix="10.0.0.0/16"
anfSubnetPrefix="10.0.1.0/24"
avsSubnetPrefix="10.0.2.0/24"

echo "🚀 Setting up Azure VMware Solution with Azure NetApp Files Datastores"

# Create resource group
echo "📁 Creating resource group $resourceGroup..."
az group create \
    --name $resourceGroup \
    --location "$location" \
    --tags $tag

# Create VNet for AVS and ANF integration
echo "🌐 Creating virtual network for AVS-ANF integration..."
az network vnet create \
    --resource-group $resourceGroup \
    --name $vnetName \
    --location "$location" \
    --address-prefix $vnetAddressPrefix

# Create ANF delegated subnet
echo "📡 Creating ANF delegated subnet..."
az network vnet subnet create \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --name $anfSubnet \
    --address-prefix $anfSubnetPrefix \
    --delegations Microsoft.NetApp/volumes

# Create subnet for AVS (for future integration)
echo "📡 Creating AVS subnet..."
az network vnet subnet create \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --name $avsSubnet \
    --address-prefix $avsSubnetPrefix

# Create NetApp account
echo "🏢 Creating NetApp account for AVS datastores..."
az netappfiles account create \
    --resource-group $resourceGroup \
    --location "$location" \
    --account-name $netAppAccount

# Create Ultra performance capacity pool for AVS
echo "💾 Creating Ultra performance capacity pool..."
az netappfiles pool create \
    --resource-group $resourceGroup \
    --location "$location" \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --size $poolSize \
    --service-level $serviceLevel

# Get subnet ID for volume creation
subnetId=$(az network vnet subnet show \
    --resource-group $resourceGroup \
    --vnet-name $vnetName \
    --name $anfSubnet \
    --query id -o tsv)

# Create ANF volume optimized for AVS datastores
echo "📀 Creating ANF volume for AVS datastore..."
az netappfiles volume create \
    --resource-group $resourceGroup \
    --location "$location" \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --name $datastoreVolume \
    --service-level $serviceLevel \
    --creation-token $datastoreVolume \
    --usage-threshold $volumeSize \
    --subnet $subnetId \
    --protocol-types $protocolTypes \
    --rule-index 1 \
    --allowed-clients "10.0.0.0/16" \
    --unix-read-write true \
    --nfsv3 true

# Configure export policy for AVS access
echo "🔐 Configuring export policy for AVS access..."
az netappfiles volume export-policy add \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --volume-name $datastoreVolume \
    --rule-index 2 \
    --allowed-clients "0.0.0.0/0" \
    --unix-read-write true \
    --unix-read-only false \
    --root-access true \
    --nfsv3 true \
    --nfsv41 false

# Get volume mount information
echo "📋 Getting volume mount information for AVS..."
mountTarget=$(az netappfiles volume show \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --name $datastoreVolume \
    --query "mountTargets[0].ipAddress" -o tsv)

creationToken=$(az netappfiles volume show \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --pool-name $capacityPool \
    --name $datastoreVolume \
    --query "creationToken" -o tsv)

echo "✅ AVS Datastore Setup Complete!"
echo ""
echo "📊 Configuration Summary:"
echo "  Resource Group: $resourceGroup"
echo "  NetApp Account: $netAppAccount"
echo "  Capacity Pool: $capacityPool (Ultra, 4 TiB)"
echo "  Datastore Volume: $datastoreVolume (1 TiB)"
echo "  Mount Target: $mountTarget"
echo "  Creation Token: $creationToken"
echo ""
echo "🔗 AVS Integration Steps:"
echo "  1. Mount Path: $mountTarget:/$creationToken"
echo "  2. In AVS vCenter: Storage > Datastores > New Datastore > NFS"
echo "  3. Enter NFS server: $mountTarget"
echo "  4. Enter folder path: /$creationToken"
echo "  5. Datastore name: ${datastoreVolume}-datastore"
echo ""
echo "📈 Performance Characteristics:"
echo "  Service Level: Ultra (128 MiB/s per TiB)"
echo "  Expected Throughput: ~128 MiB/s"
echo "  Expected IOPS: ~32,000 IOPS"
echo "  Protocol: NFSv3 (optimized for AVS)"
echo ""
echo "⚠️  Next Steps:"
echo "  1. Configure AVS private cloud to access this VNet"
echo "  2. Add datastore in AVS vCenter using the mount information above"
echo "  3. Test VM deployment and migration to the new datastore"
echo ""

# List all volumes for verification
echo "📋 Listing all volumes in the account:"
az netappfiles volume list \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --query "[].{Name:name,Size:usageThreshold,ServiceLevel:serviceLevel,State:provisioningState,MountTarget:mountTargets[0].ipAddress}" \
    --output table

# echo "🗑️  Cleanup command (run manually if needed):"
# echo "az group delete --name $resourceGroup --yes --no-wait"
