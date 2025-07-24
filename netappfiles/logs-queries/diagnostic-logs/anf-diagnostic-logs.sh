#!/bin/bash
# Azure NetApp Files Diagnostic Logs and Monitoring with Azure CLI
# Configure and query diagnostic settings for ANF resources

# Variables (customize these)
resourceGroup="your-anf-rg"
netAppAccount="your-anf-account"
logAnalyticsWorkspace="your-log-analytics-workspace"
storageAccount="your-storage-account"

echo "📊 Azure NetApp Files Diagnostic Logs Setup and Queries"
echo "======================================================"

# Function to enable diagnostic settings
enable_diagnostics() {
    echo ""
    echo "🔧 Enabling diagnostic settings for NetApp Files account..."
    
    # Get the NetApp account resource ID
    accountResourceId=$(az netappfiles account show \
        --resource-group $resourceGroup \
        --name $netAppAccount \
        --query id -o tsv)
    
    if [ -n "$accountResourceId" ]; then
        echo "✅ Found NetApp account: $accountResourceId"
        
        # Enable diagnostic settings
        az monitor diagnostic-settings create \
            --resource $accountResourceId \
            --name "anf-diagnostics" \
            --workspace $logAnalyticsWorkspace \
            --logs '[
                {
                    "category": "NetAppFileAuditLogs",
                    "enabled": true,
                    "retentionPolicy": {
                        "enabled": true,
                        "days": 30
                    }
                }
            ]' \
            --metrics '[
                {
                    "category": "AllMetrics",
                    "enabled": true,
                    "retentionPolicy": {
                        "enabled": true,
                        "days": 30
                    }
                }
            ]'
        
        echo "✅ Diagnostic settings enabled"
    else
        echo "❌ NetApp account not found"
        return 1
    fi
}

# Function to query performance metrics
query_performance_metrics() {
    echo ""
    echo "📈 Querying performance metrics..."
    
    # Get volume resource ID
    volumeResourceId=$(az netappfiles volume list \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --query "[0].id" -o tsv)
    
    if [ -n "$volumeResourceId" ]; then
        echo "📊 Volume throughput metrics (last 24 hours):"
        az monitor metrics list \
            --resource $volumeResourceId \
            --metric "VolumeReadThroughput,VolumeWriteThroughput" \
            --interval PT1H \
            --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
            --output table
        
        echo ""
        echo "📊 Volume IOPS metrics (last 24 hours):"
        az monitor metrics list \
            --resource $volumeResourceId \
            --metric "VolumeReadIops,VolumeWriteIops" \
            --interval PT1H \
            --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
            --output table
        
        echo ""
        echo "📊 Volume capacity metrics:"
        az monitor metrics list \
            --resource $volumeResourceId \
            --metric "VolumeAllocatedSize,VolumeSnapshotSize" \
            --interval PT1H \
            --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
            --output table
    else
        echo "❌ No volumes found in account"
    fi
}

# Function to query audit logs using Log Analytics
query_audit_logs() {
    echo ""
    echo "🔍 Sample Log Analytics queries for ANF audit logs..."
    echo ""
    
    echo "1. Recent file operations:"
    echo "AzureDiagnostics"
    echo "| where ResourceProvider == \"MICROSOFT.NETAPP\""
    echo "| where Category == \"NetAppFileAuditLogs\""
    echo "| where TimeGenerated > ago(1d)"
    echo "| project TimeGenerated, OperationName, ResourceGroup, Resource, ResultDescription"
    echo "| order by TimeGenerated desc"
    echo ""
    
    echo "2. Failed operations:"
    echo "AzureDiagnostics"
    echo "| where ResourceProvider == \"MICROSOFT.NETAPP\""
    echo "| where Category == \"NetAppFileAuditLogs\""
    echo "| where ResultType != \"Success\""
    echo "| project TimeGenerated, OperationName, ResultType, ResultDescription"
    echo "| order by TimeGenerated desc"
    echo ""
    
    echo "3. Operations by user:"
    echo "AzureDiagnostics"
    echo "| where ResourceProvider == \"MICROSOFT.NETAPP\""
    echo "| where Category == \"NetAppFileAuditLogs\""
    echo "| summarize count() by Caller, OperationName"
    echo "| order by count_ desc"
    echo ""
    
    echo "4. Volume creation/deletion events:"
    echo "AzureDiagnostics"
    echo "| where ResourceProvider == \"MICROSOFT.NETAPP\""
    echo "| where OperationName contains \"volume\""
    echo "| where OperationName contains \"write\" or OperationName contains \"delete\""
    echo "| project TimeGenerated, OperationName, ResourceGroup, Resource, Caller"
    echo "| order by TimeGenerated desc"
    echo ""
    
    echo "💡 To run these queries:"
    echo "1. Go to Azure portal > Log Analytics workspace"
    echo "2. Select 'Logs' from the left menu"
    echo "3. Copy and paste any query above"
    echo "4. Click 'Run' to execute"
}

# Function to set up alerts
setup_alerts() {
    echo ""
    echo "🚨 Setting up monitoring alerts..."
    
    # Get volume resource ID for alerts
    volumeResourceId=$(az netappfiles volume list \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --query "[0].id" -o tsv)
    
    if [ -n "$volumeResourceId" ]; then
        # Create action group for notifications
        echo "📧 Creating action group for notifications..."
        az monitor action-group create \
            --resource-group $resourceGroup \
            --name "anf-alerts" \
            --short-name "anf-alerts"
        
        # High throughput alert
        echo "⚡ Creating high throughput alert..."
        az monitor metrics alert create \
            --name "ANF-High-Throughput" \
            --resource-group $resourceGroup \
            --scopes $volumeResourceId \
            --condition "avg VolumeReadThroughput > 100000000" \
            --description "Alert when volume read throughput exceeds 100 MB/s" \
            --evaluation-frequency PT5M \
            --window-size PT15M \
            --severity 2 \
            --action /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/anf-alerts
        
        # High capacity usage alert
        echo "💾 Creating high capacity usage alert..."
        az monitor metrics alert create \
            --name "ANF-High-Capacity" \
            --resource-group $resourceGroup \
            --scopes $volumeResourceId \
            --condition "avg VolumeAllocatedSize > 858993459200" \
            --description "Alert when volume usage exceeds 80% (800GB)" \
            --evaluation-frequency PT5M \
            --window-size PT15M \
            --severity 2 \
            --action /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroup/providers/microsoft.insights/actionGroups/anf-alerts
        
        echo "✅ Alerts configured successfully"
    else
        echo "❌ No volumes found for alert configuration"
    fi
}

# Function to check current diagnostic settings
check_diagnostics() {
    echo ""
    echo "🔍 Checking current diagnostic settings..."
    
    accountResourceId=$(az netappfiles account show \
        --resource-group $resourceGroup \
        --name $netAppAccount \
        --query id -o tsv)
    
    if [ -n "$accountResourceId" ]; then
        az monitor diagnostic-settings list \
            --resource $accountResourceId \
            --output table
    else
        echo "❌ NetApp account not found"
    fi
}

# Function to export metrics to storage
export_metrics() {
    echo ""
    echo "📤 Configuring metrics export to storage account..."
    
    accountResourceId=$(az netappfiles account show \
        --resource-group $resourceGroup \
        --name $netAppAccount \
        --query id -o tsv)
    
    storageAccountId=$(az storage account show \
        --name $storageAccount \
        --resource-group $resourceGroup \
        --query id -o tsv)
    
    if [ -n "$accountResourceId" ] && [ -n "$storageAccountId" ]; then
        az monitor diagnostic-settings create \
            --resource $accountResourceId \
            --name "anf-storage-export" \
            --storage-account $storageAccountId \
            --metrics '[
                {
                    "category": "AllMetrics",
                    "enabled": true,
                    "retentionPolicy": {
                        "enabled": true,
                        "days": 90
                    }
                }
            ]'
        
        echo "✅ Metrics export to storage configured"
    else
        echo "❌ NetApp account or storage account not found"
    fi
}

# Main menu
echo ""
echo "Select an operation:"
echo "1. Enable diagnostic settings"
echo "2. Query performance metrics"
echo "3. Show Log Analytics query examples"
echo "4. Set up monitoring alerts"
echo "5. Check current diagnostic settings"
echo "6. Export metrics to storage"
echo "7. Run all operations"
echo ""

read -p "Enter your choice (1-7): " choice

case $choice in
    1)
        enable_diagnostics
        ;;
    2)
        query_performance_metrics
        ;;
    3)
        query_audit_logs
        ;;
    4)
        setup_alerts
        ;;
    5)
        check_diagnostics
        ;;
    6)
        export_metrics
        ;;
    7)
        enable_diagnostics
        query_performance_metrics
        query_audit_logs
        setup_alerts
        check_diagnostics
        ;;
    *)
        echo "Invalid choice. Please run the script again."
        ;;
esac

echo ""
echo "📊 Available metrics for NetApp Files volumes:"
echo "  • VolumeAllocatedSize - Current allocated size"
echo "  • VolumeSnapshotSize - Total snapshot size"
echo "  • VolumeReadThroughput - Read throughput in bytes/sec"
echo "  • VolumeWriteThroughput - Write throughput in bytes/sec"
echo "  • VolumeReadIops - Read IOPS"
echo "  • VolumeWriteIops - Write IOPS"
echo "  • VolumeThroughputPercentage - Throughput percentage used"
echo ""
echo "🔗 Useful links:"
echo "  • ANF monitoring: https://docs.microsoft.com/azure/azure-netapp-files/azure-netapp-files-metrics"
echo "  • Log Analytics: https://docs.microsoft.com/azure/azure-monitor/logs/"
echo "  • Alerts: https://docs.microsoft.com/azure/azure-monitor/alerts/"
echo ""
echo "✅ Diagnostic logs and monitoring setup complete!"
