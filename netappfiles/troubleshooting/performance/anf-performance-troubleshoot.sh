#!/bin/bash
# Azure NetApp Files Performance Troubleshooting Script
# Analyzes performance issues and provides optimization recommendations

# Variables (customize these)
resourceGroup="your-anf-rg"
netAppAccount="your-anf-account"
capacityPool="your-pool"
volumeName="your-volume"
subscriptionId=""  # Will be detected automatically if empty

echo "📊 Azure NetApp Files Performance Troubleshooting"
echo "================================================="

# Function to detect subscription ID
detect_subscription() {
    if [ -z "$subscriptionId" ]; then
        echo "🔍 Detecting subscription ID..."
        subscriptionId=$(az account show --query id -o tsv 2>/dev/null)
        echo "📍 Using subscription: $subscriptionId"
    fi
}

# Function to get volume performance metrics
get_volume_performance_metrics() {
    echo ""
    echo "📈 Getting volume performance metrics..."
    
    # Get basic volume info
    volume_info=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "{Name:name,Size:usageThreshold,ServiceLevel:serviceLevel,State:provisioningState,ThroughputMib:throughputMibps}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Volume performance configuration:"
        echo "$volume_info" | jq .
        
        # Extract key metrics
        serviceLevel=$(echo "$volume_info" | jq -r '.ServiceLevel')
        throughputMib=$(echo "$volume_info" | jq -r '.ThroughputMib')
        volumeSize=$(echo "$volume_info" | jq -r '.Size')
        
        echo ""
        echo "🎯 Performance Summary:"
        echo "   Service Level: $serviceLevel"
        echo "   Throughput Limit: $throughputMib MiB/s"
        echo "   Volume Size: $((volumeSize / 1024 / 1024 / 1024)) GiB"
        
        return 0
    else
        echo "❌ Could not retrieve volume information"
        return 1
    fi
}

# Function to get Azure Monitor metrics
get_azure_monitor_metrics() {
    echo ""
    echo "📊 Getting Azure Monitor performance metrics..."
    
    # Get resource ID
    resourceId="/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.NetApp/netAppAccounts/$netAppAccount/capacityPools/$capacityPool/volumes/$volumeName"
    
    # Get last 24 hours of metrics
    startTime=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)
    endTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    echo "📅 Time range: $startTime to $endTime"
    
    # Get volume read throughput
    echo ""
    echo "📈 Volume Read Throughput:"
    read_throughput=$(az monitor metrics list \
        --resource "$resourceId" \
        --metric "VolumeReadThroughput" \
        --start-time "$startTime" \
        --end-time "$endTime" \
        --interval PT1H \
        --aggregation Average \
        --output json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$read_throughput" != "null" ]; then
        echo "$read_throughput" | jq -r '.value[0].timeseries[0].data[] | "   \(.timeStamp): \(.average // "No data") bytes/sec"' | tail -5
    else
        echo "   ⚠️ No read throughput data available"
    fi
    
    # Get volume write throughput
    echo ""
    echo "📈 Volume Write Throughput:"
    write_throughput=$(az monitor metrics list \
        --resource "$resourceId" \
        --metric "VolumeWriteThroughput" \
        --start-time "$startTime" \
        --end-time "$endTime" \
        --interval PT1H \
        --aggregation Average \
        --output json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$write_throughput" != "null" ]; then
        echo "$write_throughput" | jq -r '.value[0].timeseries[0].data[] | "   \(.timeStamp): \(.average // "No data") bytes/sec"' | tail -5
    else
        echo "   ⚠️ No write throughput data available"
    fi
    
    # Get volume IOPS
    echo ""
    echo "📈 Volume IOPS:"
    iops_metrics=$(az monitor metrics list \
        --resource "$resourceId" \
        --metric "VolumeReadIops,VolumeWriteIops" \
        --start-time "$startTime" \
        --end-time "$endTime" \
        --interval PT1H \
        --aggregation Average \
        --output json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$iops_metrics" != "null" ]; then
        echo "$iops_metrics" | jq -r '.value[] | "   \(.name.value): \(.timeseries[0].data[-1].average // "No data") IOPS"'
    else
        echo "   ⚠️ No IOPS data available"
    fi
}

# Function to analyze capacity pool performance
analyze_capacity_pool_performance() {
    echo ""
    echo "🏊 Analyzing capacity pool performance..."
    
    pool_info=$(az netappfiles pool show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --name $capacityPool \
        --query "{Name:name,Size:size,ServiceLevel:serviceLevel,UtilizedThroughputMibps:utilizedThroughputMibps}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Capacity pool configuration:"
        echo "$pool_info" | jq .
        
        poolSize=$(echo "$pool_info" | jq -r '.Size')
        serviceLevel=$(echo "$pool_info" | jq -r '.ServiceLevel')
        utilizedThroughput=$(echo "$pool_info" | jq -r '.UtilizedThroughputMibps // 0')
        
        # Calculate theoretical maximum throughput based on service level
        case "$serviceLevel" in
            "Standard")
                maxThroughputPerTiB=16
                ;;
            "Premium")
                maxThroughputPerTiB=64
                ;;
            "Ultra")
                maxThroughputPerTiB=128
                ;;
            *)
                maxThroughputPerTiB=16
                ;;
        esac
        
        poolSizeTiB=$((poolSize / 1024 / 1024 / 1024 / 1024))
        maxPoolThroughput=$((poolSizeTiB * maxThroughputPerTiB))
        
        echo ""
        echo "🎯 Pool Performance Analysis:"
        echo "   Pool Size: $poolSizeTiB TiB"
        echo "   Service Level: $serviceLevel"
        echo "   Max Throughput: $maxPoolThroughput MiB/s"
        echo "   Utilized Throughput: $utilizedThroughput MiB/s"
        
        if [ "$utilizedThroughput" != "0" ]; then
            utilizationPercent=$(echo "scale=1; $utilizedThroughput * 100 / $maxPoolThroughput" | bc)
            echo "   Utilization: $utilizationPercent%"
            
            if (( $(echo "$utilizationPercent > 80" | bc -l) )); then
                echo "   ⚠️ High utilization detected - consider scaling up"
            fi
        fi
    else
        echo "❌ Could not retrieve capacity pool information"
    fi
}

# Function to check for performance bottlenecks
check_performance_bottlenecks() {
    echo ""
    echo "🔍 Checking for performance bottlenecks..."
    
    # Check mount options (if possible to detect)
    echo ""
    echo "📋 Mount Options Recommendations:"
    echo "   For optimal performance, use these mount options:"
    echo "   • NFS v3: mount -t nfs -o rsize=1048576,wsize=1048576,hard,intr,vers=3"
    echo "   • NFS v4.1: mount -t nfs -o rsize=1048576,wsize=1048576,hard,intr,vers=4.1"
    
    # Check for common issues
    echo ""
    echo "🔧 Common Performance Issues:"
    
    # Service level analysis
    if [ "$serviceLevel" = "Standard" ]; then
        echo "   ⚠️ Standard service level has lower performance limits"
        echo "     Consider upgrading to Premium or Ultra for better performance"
    fi
    
    # Volume size analysis
    volumeSizeGiB=$((volumeSize / 1024 / 1024 / 1024))
    if [ $volumeSizeGiB -lt 100 ]; then
        echo "   ⚠️ Small volume size may limit performance"
        echo "     Larger volumes get higher throughput allocations"
    fi
    
    # Regional considerations
    echo ""
    echo "🌍 Regional Performance Considerations:"
    echo "   • Ensure clients are in the same Azure region"
    echo "   • Use availability zones for high availability"
    echo "   • Consider proximity placement groups for VMs"
}

# Function to run performance tests
run_performance_tests() {
    echo ""
    echo "🧪 Performance Testing Recommendations:"
    echo ""
    echo "To test performance, run these commands on your client:"
    echo ""
    echo "1. Sequential Read Test:"
    echo "   dd if=/mnt/anf/testfile of=/dev/null bs=1M count=1000"
    echo ""
    echo "2. Sequential Write Test:"
    echo "   dd if=/dev/zero of=/mnt/anf/testfile bs=1M count=1000 conv=fdatasync"
    echo ""
    echo "3. Random I/O Test (requires fio):"
    echo "   fio --name=randrw --ioengine=libaio --iodepth=32 --rw=randrw --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 --group_reporting --filename=/mnt/anf/fiotest"
    echo ""
    echo "4. Network Latency Test:"
    echo "   ping -c 10 $mountIP"
    echo ""
}

# Function to provide performance optimization recommendations
performance_recommendations() {
    echo ""
    echo "💡 Performance Optimization Recommendations"
    echo "=========================================="
    echo ""
    echo "1. 🚀 Service Level Optimization:"
    echo "   • Standard: 16 MiB/s per TiB"
    echo "   • Premium: 64 MiB/s per TiB (4x faster)"
    echo "   • Ultra: 128 MiB/s per TiB (8x faster)"
    echo ""
    echo "2. 📏 Volume Sizing:"
    echo "   • Larger volumes get higher throughput allocations"
    echo "   • Minimum 100 GiB for meaningful performance"
    echo "   • Consider over-provisioning for performance"
    echo ""
    echo "3. 🔧 Client Optimization:"
    echo "   • Use recommended mount options"
    echo "   • Increase read/write buffer sizes (rsize/wsize=1048576)"
    echo "   • Use multiple concurrent connections"
    echo ""
    echo "4. 🌐 Network Optimization:"
    echo "   • Ensure clients are in the same region"
    echo "   • Use accelerated networking on VMs"
    echo "   • Consider proximity placement groups"
    echo ""
    echo "5. 📊 Monitoring:"
    echo "   • Set up Azure Monitor alerts for key metrics"
    echo "   • Monitor volume utilization vs. limits"
    echo "   • Track IOPS and throughput patterns"
    echo ""
    echo "Example Azure CLI commands for optimization:"
    echo ""
    echo "# Upgrade service level to Premium"
    echo "az netappfiles pool update \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --name $capacityPool \\"
    echo "  --service-level Premium"
    echo ""
    echo "# Increase volume size"
    echo "az netappfiles volume update \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --name $volumeName \\"
    echo "  --usage-threshold 2199023255552  # 2 TiB"
}

# Main execution
detect_subscription

if get_volume_performance_metrics; then
    get_azure_monitor_metrics
    analyze_capacity_pool_performance
    check_performance_bottlenecks
    run_performance_tests
    performance_recommendations
else
    echo "❌ Cannot proceed without valid volume information"
    exit 1
fi

echo ""
echo "🏁 Performance troubleshooting complete!"
echo "For additional optimization help, consult Azure NetApp Files performance documentation."
