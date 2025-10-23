#!/bin/bash
# Passed validation in Cloud Shell on 07/19/2025

# <FullScript>
# Volume backup configuration

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-netappfiles-rg-$randomIdentifier"
tag="volume-backup-netappfiles"
netAppAccount="msdocs-netapp-account-$randomIdentifier"
capacityPool="msdocs-pool-$randomIdentifier"
volume="msdocs-volume-$randomIdentifier"
backupPolicy="msdocs-backup-policy-$randomIdentifier"
serviceLevel="Premium"
poolSize="4398046511104" # 4 TiB
volumeSize="107374182400" # 100 GiB

echo "Setting up volume backup configuration..."

# Create basic NetApp infrastructure (abbreviated)
az group create --name $resourceGroup --location "$location" --tags $tag
az netappfiles account create --resource-group $resourceGroup --location "$location" --account-name $netAppAccount
az netappfiles pool create --resource-group $resourceGroup --location "$location" --account-name $netAppAccount --pool-name $capacityPool --size $poolSize --service-level $serviceLevel

# Create backup policy
echo "Creating backup policy $backupPolicy"
az netappfiles account backup-policy create \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --backup-policy-name $backupPolicy \
    --location "$location" \
    --daily-backups 10 \
    --weekly-backups 4 \
    --monthly-backups 3 \
    --enabled true

# List backup policies
echo "Listing backup policies for $netAppAccount"
az netappfiles account backup-policy list \
    --resource-group $resourceGroup \
    --account-name $netAppAccount \
    --query "[].{Name:name,DailyBackups:dailyBackupsToKeep,WeeklyBackups:weeklyBackupsToKeep,MonthlyBackups:monthlyBackupsToKeep}" \
    --output table

# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
