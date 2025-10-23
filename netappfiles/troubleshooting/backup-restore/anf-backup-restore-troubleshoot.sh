#!/bin/bash
# Azure NetApp Files Backup and Restore Troubleshooting Script
# Diagnoses backup and restore issues and provides solutions

# Variables (customize these)
resourceGroup="your-anf-rg"
netAppAccount="your-anf-account"
capacityPool="your-pool"
volumeName="your-volume"
backupPolicyName="your-backup-policy"
subscriptionId=""  # Will be detected automatically if empty

echo "💾 Azure NetApp Files Backup & Restore Troubleshooting"
echo "======================================================"

# Function to detect subscription ID
detect_subscription() {
    if [ -z "$subscriptionId" ]; then
        echo "🔍 Detecting subscription ID..."
        subscriptionId=$(az account show --query id -o tsv 2>/dev/null)
        echo "📍 Using subscription: $subscriptionId"
    fi
}

# Function to check backup configuration
check_backup_configuration() {
    echo ""
    echo "🔧 Checking backup configuration..."
    
    # Get volume backup configuration
    volume_backup_info=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "{Name:name,BackupEnabled:dataProtection.backup.backupEnabled,PolicyId:dataProtection.backup.policyEnforced,VaultId:dataProtection.backup.vaultId}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Volume backup configuration:"
        echo "$volume_backup_info" | jq .
        
        backupEnabled=$(echo "$volume_backup_info" | jq -r '.BackupEnabled // false')
        policyId=$(echo "$volume_backup_info" | jq -r '.PolicyId // "none"')
        vaultId=$(echo "$volume_backup_info" | jq -r '.VaultId // "none"')
        
        if [ "$backupEnabled" = "true" ]; then
            echo "✅ Backup is enabled for this volume"
        else
            echo "❌ Backup is NOT enabled for this volume"
            return 1
        fi
        
        if [ "$policyId" != "none" ] && [ "$policyId" != "null" ]; then
            echo "✅ Backup policy is configured: $policyId"
        else
            echo "⚠️ No backup policy configured"
        fi
        
        if [ "$vaultId" != "none" ] && [ "$vaultId" != "null" ]; then
            echo "✅ Backup vault is configured: $vaultId"
        else
            echo "⚠️ No backup vault configured"
        fi
        
    else
        echo "❌ Could not retrieve volume backup configuration"
        return 1
    fi
}

# Function to list backup policies
list_backup_policies() {
    echo ""
    echo "📋 Listing backup policies..."
    
    backup_policies=$(az netappfiles account backup-policy list \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --query "[].{Name:name,DailyBackups:dailyBackupsToKeep,WeeklyBackups:weeklyBackupsToKeep,MonthlyBackups:monthlyBackupsToKeep,State:provisioningState}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$backup_policies" != "[]" ]; then
        echo "✅ Available backup policies:"
        echo "$backup_policies" | jq .
    else
        echo "⚠️ No backup policies found or error retrieving policies"
        echo ""
        echo "To create a backup policy, use:"
        echo "az netappfiles account backup-policy create \\"
        echo "  --resource-group $resourceGroup \\"
        echo "  --account-name $netAppAccount \\"
        echo "  --backup-policy-name \"daily-backup-policy\" \\"
        echo "  --location \"\$(az group show -n $resourceGroup --query location -o tsv)\" \\"
        echo "  --daily-backups 7 \\"
        echo "  --weekly-backups 4 \\"
        echo "  --monthly-backups 12 \\"
        echo "  --enabled true"
    fi
}

# Function to check backup status and list backups
check_backup_status() {
    echo ""
    echo "📊 Checking backup status and listing recent backups..."
    
    # List backups for the volume
    backups=$(az netappfiles volume backup list \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --volume-name $volumeName \
        --query "[].{Name:name,CreationDate:creationDate,Size:size,BackupType:backupType,ProvisioningState:provisioningState}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        if [ "$backups" != "[]" ]; then
            echo "✅ Recent backups found:"
            echo "$backups" | jq 'sort_by(.CreationDate) | reverse | .[0:5]'
            
            # Check for failed backups
            failed_backups=$(echo "$backups" | jq '[.[] | select(.ProvisioningState != "Succeeded")]')
            if [ "$failed_backups" != "[]" ]; then
                echo ""
                echo "❌ Failed backups detected:"
                echo "$failed_backups" | jq .
            fi
        else
            echo "⚠️ No backups found for this volume"
        fi
    else
        echo "❌ Could not retrieve backup information"
    fi
}

# Function to check backup vault configuration
check_backup_vault() {
    echo ""
    echo "🏦 Checking backup vault configuration..."
    
    # List backup vaults in the resource group
    backup_vaults=$(az netappfiles account backup-vault list \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --query "[].{Name:name,ProvisioningState:provisioningState}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        if [ "$backup_vaults" != "[]" ]; then
            echo "✅ Backup vaults found:"
            echo "$backup_vaults" | jq .
        else
            echo "⚠️ No backup vaults found"
            echo ""
            echo "To create a backup vault, use:"
            echo "az netappfiles account backup-vault create \\"
            echo "  --resource-group $resourceGroup \\"
            echo "  --account-name $netAppAccount \\"
            echo "  --backup-vault-name \"backup-vault-1\" \\"
            echo "  --location \"\$(az group show -n $resourceGroup --query location -o tsv)\""
        fi
    else
        echo "❌ Could not retrieve backup vault information"
    fi
}

# Function to diagnose common backup issues
diagnose_backup_issues() {
    echo ""
    echo "🔍 Diagnosing common backup issues..."
    
    echo ""
    echo "1. 🔐 Permissions Check:"
    echo "   Ensure the NetApp resource provider has proper permissions:"
    echo "   • Contributor role on the resource group"
    echo "   • Storage Account Contributor on backup storage account"
    
    echo ""
    echo "2. 🌍 Regional Availability:"
    echo "   Verify Azure NetApp Files backup is available in your region:"
    location=$(az group show --name $resourceGroup --query location -o tsv 2>/dev/null)
    echo "   Current region: $location"
    echo "   Backup is available in most Azure regions - check Azure documentation"
    
    echo ""
    echo "3. 📊 Quota and Limits:"
    echo "   Check for quota limitations:"
    echo "   • Maximum backups per volume: 1024"
    echo "   • Maximum backup policies per NetApp account: 100"
    echo "   • Backup retention: Up to 1 year"
    
    echo ""
    echo "4. 🔄 Backup Schedule:"
    echo "   Verify backup policy schedule alignment:"
    echo "   • Daily backups: Occur once per day"
    echo "   • Weekly backups: Occur on Sunday"
    echo "   • Monthly backups: Occur on the 1st of each month"
    
    echo ""
    echo "5. 💾 Storage Requirements:"
    echo "   Backup storage considerations:"
    echo "   • Backup size depends on data change rate"
    echo "   • First backup is a full backup"
    echo "   • Subsequent backups are incremental"
}

# Function to test backup functionality
test_backup_functionality() {
    echo ""
    echo "🧪 Testing backup functionality..."
    
    # Create a manual backup for testing
    backup_name="manual-test-backup-$(date +%Y%m%d-%H%M%S)"
    
    echo "Creating manual backup: $backup_name"
    echo "Command to execute:"
    echo "az netappfiles volume backup create \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --volume-name $volumeName \\"
    echo "  --backup-name \"$backup_name\" \\"
    echo "  --location \"\$(az group show -n $resourceGroup --query location -o tsv)\""
    
    echo ""
    echo "💡 To execute this backup, run the command above"
    echo "Monitor backup progress with:"
    echo "az netappfiles volume backup show \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --volume-name $volumeName \\"
    echo "  --backup-name \"$backup_name\""
}

# Function to provide restore guidance
restore_guidance() {
    echo ""
    echo "🔄 Restore Operations Guidance"
    echo "=============================="
    
    echo ""
    echo "1. 📋 List Available Backups:"
    echo "az netappfiles volume backup list \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --volume-name $volumeName"
    
    echo ""
    echo "2. 🔄 Restore from Backup (Create New Volume):"
    echo "az netappfiles volume create \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --name \"restored-volume-name\" \\"
    echo "  --location \"\$(az group show -n $resourceGroup --query location -o tsv)\" \\"
    echo "  --service-level Premium \\"
    echo "  --usage-threshold 107374182400 \\"
    echo "  --vnet \"your-vnet\" \\"
    echo "  --subnet \"your-subnet\" \\"
    echo "  --creation-token \"restored-volume\" \\"
    echo "  --backup-id \"/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.NetApp/netAppAccounts/$netAppAccount/capacityPools/$capacityPool/volumes/$volumeName/backups/BACKUP_NAME\""
    
    echo ""
    echo "3. 📸 Restore from Snapshot (Alternative):"
    echo "# List snapshots"
    echo "az netappfiles snapshot list \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --volume-name $volumeName"
    echo ""
    echo "# Restore from snapshot"
    echo "az netappfiles volume revert \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --name $volumeName \\"
    echo "  --snapshot-id \"/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.NetApp/netAppAccounts/$netAppAccount/capacityPools/$capacityPool/volumes/$volumeName/snapshots/SNAPSHOT_NAME\""
    
    echo ""
    echo "4. ⚠️ Restore Considerations:"
    echo "   • Backup restores create a new volume"
    echo "   • Snapshot reverts modify the existing volume"
    echo "   • Test restores in a separate environment first"
    echo "   • Verify data integrity after restore"
    echo "   • Update application connection strings if needed"
}

# Function to monitor backup operations
monitor_backup_operations() {
    echo ""
    echo "📊 Monitoring Backup Operations"
    echo "==============================="
    
    echo ""
    echo "1. 🔍 Check Backup Job Status:"
    echo "az netappfiles volume backup show \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --volume-name $volumeName \\"
    echo "  --backup-name \"BACKUP_NAME\""
    
    echo ""
    echo "2. 📈 Azure Monitor Integration:"
    echo "   Set up monitoring alerts for:"
    echo "   • Backup completion status"
    echo "   • Backup failure notifications"
    echo "   • Backup size trends"
    
    echo ""
    echo "3. 📋 Regular Health Checks:"
    echo "   • Verify backup policies are active"
    echo "   • Check backup success rates"
    echo "   • Monitor backup storage consumption"
    echo "   • Test restore procedures regularly"
    
    echo ""
    echo "Example monitoring query (Azure Resource Graph):"
    echo "Resources"
    echo "| where type == 'microsoft.netapp/netappaccounts/capacitypools/volumes/backups'"
    echo "| where resourceGroup == '$resourceGroup'"
    echo "| project name, properties.provisioningState, properties.creationDate"
    echo "| order by properties_creationDate desc"
}

# Main execution
detect_subscription

echo "Starting comprehensive backup and restore troubleshooting..."

if check_backup_configuration; then
    list_backup_policies
    check_backup_status
    check_backup_vault
    diagnose_backup_issues
    test_backup_functionality
    restore_guidance
    monitor_backup_operations
else
    echo ""
    echo "❌ Backup is not properly configured. Here's how to enable it:"
    echo ""
    echo "1. Create a backup vault:"
    echo "az netappfiles account backup-vault create \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --backup-vault-name \"backup-vault-1\" \\"
    echo "  --location \"\$(az group show -n $resourceGroup --query location -o tsv)\""
    echo ""
    echo "2. Create a backup policy:"
    echo "az netappfiles account backup-policy create \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --backup-policy-name \"daily-backup-policy\" \\"
    echo "  --location \"\$(az group show -n $resourceGroup --query location -o tsv)\" \\"
    echo "  --daily-backups 7 \\"
    echo "  --weekly-backups 4 \\"
    echo "  --monthly-backups 12 \\"
    echo "  --enabled true"
    echo ""
    echo "3. Enable backup on the volume:"
    echo "az netappfiles volume update \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --name $volumeName \\"
    echo "  --backup-enabled true \\"
    echo "  --backup-policy-id \"/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.NetApp/netAppAccounts/$netAppAccount/backupPolicies/daily-backup-policy\" \\"
    echo "  --vault-id \"/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.NetApp/netAppAccounts/$netAppAccount/backupVaults/backup-vault-1\""
fi

echo ""
echo "🏁 Backup and restore troubleshooting complete!"
echo "For additional help, consult Azure NetApp Files backup documentation."
