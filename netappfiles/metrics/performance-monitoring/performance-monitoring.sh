#!/bin/bash
# Passed validation in Cloud Shell on 07/19/2025

# <FullScript>
# Performance monitoring

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-netappfiles-rg-$randomIdentifier"
tag="performance-monitoring-netappfiles"
netAppAccount="msdocs-netapp-account-$randomIdentifier"
capacityPool="msdocs-pool-$randomIdentifier"
volume="msdocs-volume-$randomIdentifier"
serviceLevel="Premium"

echo "Setting up performance monitoring for NetApp volumes..."

# Create basic NetApp infrastructure (abbreviated)
az group create --name $resourceGroup --location "$location" --tags $tag
az netappfiles account create --resource-group $resourceGroup --location "$location" --account-name $netAppAccount

# Monitor volume performance metrics (requires existing volume)
echo "Available monitoring commands for NetApp volumes:"
echo "1. View volume performance metrics"
echo "   az monitor metrics list --resource <volume-resource-id> --metric 'VolumeLogicalSize'"

echo "2. Create performance alert rules" 
echo "   az monitor metrics alert create --name 'ANF Volume Size Alert' --resource-group $resourceGroup"

echo "3. Monitor throughput and IOPS"
echo "   az monitor metrics list --resource <volume-resource-id> --metric 'AverageReadLatency,AverageWriteLatency'"

echo "Performance monitoring requires active volumes with metrics data"
echo "See Azure Monitor documentation for complete monitoring setup"

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
