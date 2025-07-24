#!/bin/bash
# AVS + Azure NetApp Files Troubleshooting Script
# Diagnoses common issues with ANF datastores in Azure VMware Solution

# Variables (customize these)
resourceGroup="your-avs-anf-rg"
netAppAccount="your-anf-account"
capacityPool="your-pool"
volumeName="your-datastore-volume"
avsPrivateCloudName="your-avs-cloud"

echo "🔍 AVS + Azure NetApp Files Troubleshooting"
echo "============================================="

# Function to check ANF volume health
check_anf_volume() {
    echo ""
    echo "📀 Checking ANF Volume Health..."
    
    volume_info=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "{Name:name,State:provisioningState,Size:usageThreshold,ServiceLevel:serviceLevel,MountTargets:mountTargets}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Volume found and accessible"
        echo "$volume_info" | jq .
        
        # Check if volume is ready
        state=$(echo "$volume_info" | jq -r '.State')
        if [ "$state" = "Succeeded" ]; then
            echo "✅ Volume is in 'Succeeded' state"
        else
            echo "⚠️  Volume state: $state (not ready for use)"
        fi
    else
        echo "❌ Volume not found or inaccessible"
        echo "   Check resource group, account, pool, and volume names"
        return 1
    fi
}

# Function to check network connectivity
check_network_connectivity() {
    echo ""
    echo "🌐 Checking Network Connectivity..."
    
    # Get mount target IP
    mountIP=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "mountTargets[0].ipAddress" -o tsv 2>/dev/null)
    
    if [ -n "$mountIP" ]; then
        echo "✅ Mount target IP: $mountIP"
        
        # Check if ping is possible (may not work due to ICMP restrictions)
        echo "🔍 Testing connectivity to mount target..."
        if ping -c 3 $mountIP >/dev/null 2>&1; then
            echo "✅ Ping successful to $mountIP"
        else
            echo "⚠️  Ping failed (this may be normal - ICMP might be blocked)"
        fi
        
        # Check if port 2049 (NFS) is accessible
        echo "🔍 Testing NFS port 2049..."
        if timeout 5 bash -c "</dev/tcp/$mountIP/2049" 2>/dev/null; then
            echo "✅ Port 2049 (NFS) is accessible"
        else
            echo "❌ Port 2049 (NFS) is not accessible"
            echo "   Check NSG rules and export policies"
        fi
    else
        echo "❌ Could not retrieve mount target IP"
        return 1
    fi
}

# Function to check export policies
check_export_policies() {
    echo ""
    echo "🔐 Checking Export Policies..."
    
    export_policy=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "exportPolicy" -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "📋 Current export policy:"
        echo "$export_policy" | jq .
        
        # Check for common issues
        rules_count=$(echo "$export_policy" | jq '.rules | length')
        echo "📊 Number of export rules: $rules_count"
        
        if [ "$rules_count" -eq 0 ]; then
            echo "⚠️  No export rules found - volume won't be accessible"
        else
            echo "✅ Export rules configured"
            
            # Check if NFSv3 is enabled
            nfsv3_enabled=$(echo "$export_policy" | jq -r '.rules[0].nfsv3')
            if [ "$nfsv3_enabled" = "true" ]; then
                echo "✅ NFSv3 enabled (required for AVS)"
            else
                echo "❌ NFSv3 not enabled (required for AVS datastores)"
            fi
        fi
    else
        echo "❌ Could not retrieve export policy"
    fi
}

# Function to check performance metrics
check_performance() {
    echo ""
    echo "📊 Checking Performance Metrics..."
    
    # Get volume details for performance calculation
    volume_size=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "usageThreshold" -o tsv 2>/dev/null)
    
    service_level=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "serviceLevel" -o tsv 2>/dev/null)
    
    if [ -n "$volume_size" ] && [ -n "$service_level" ]; then
        # Convert bytes to TB
        size_tb=$(echo "scale=2; $volume_size / 1099511627776" | bc)
        
        echo "📏 Volume size: ${size_tb} TB"
        echo "🏎️  Service level: $service_level"
        
        # Calculate expected performance
        case $service_level in
            "Standard")
                throughput_per_tb=16
                iops_per_tb=4000
                ;;
            "Premium")
                throughput_per_tb=64
                iops_per_tb=16000
                ;;
            "Ultra")
                throughput_per_tb=128
                iops_per_tb=32000
                ;;
            *)
                echo "❓ Unknown service level: $service_level"
                return 1
                ;;
        esac
        
        expected_throughput=$(echo "scale=0; $size_tb * $throughput_per_tb" | bc)
        expected_iops=$(echo "scale=0; $size_tb * $iops_per_tb" | bc)
        
        echo "📈 Expected performance:"
        echo "   Throughput: ~${expected_throughput} MiB/s"
        echo "   IOPS: ~${expected_iops}"
        
        if [ "$service_level" = "Ultra" ]; then
            echo "✅ Ultra service level - optimal for AVS datastores"
        else
            echo "⚠️  Consider Ultra service level for best AVS performance"
        fi
    fi
}

# Function to provide AVS-specific guidance
avs_guidance() {
    echo ""
    echo "🎯 AVS-Specific Guidance"
    echo "========================"
    
    echo "📋 Mount command for AVS vCenter:"
    mountIP=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "mountTargets[0].ipAddress" -o tsv 2>/dev/null)
    
    creationToken=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "creationToken" -o tsv 2>/dev/null)
    
    if [ -n "$mountIP" ] && [ -n "$creationToken" ]; then
        echo "   NFS Server: $mountIP"
        echo "   Folder: /$creationToken"
        echo ""
        echo "🔧 vCenter datastore setup:"
        echo "   1. Storage > Datastores > New Datastore"
        echo "   2. Select 'NFS' as datastore type"
        echo "   3. Enter server: $mountIP"
        echo "   4. Enter folder: /$creationToken"
        echo "   5. Datastore name: ${volumeName}-datastore"
    fi
    
    echo ""
    echo "✅ Best practices for AVS + ANF:"
    echo "   • Use Ultra service level for production workloads"
    echo "   • Size volumes appropriately for performance needs"
    echo "   • Monitor performance metrics regularly"
    echo "   • Use multiple smaller volumes instead of one large volume"
    echo "   • Implement backup strategy using ANF snapshots"
    echo ""
    echo "⚠️  Common issues and solutions:"
    echo "   • Mount fails: Check export policies and network connectivity"
    echo "   • Slow performance: Verify service level and volume size"
    echo "   • Connection timeouts: Check NSG rules for port 2049"
    echo "   • Access denied: Verify export policy allows AVS subnet"
}

# Function to run all checks
run_all_checks() {
    echo "🚀 Running comprehensive AVS + ANF diagnostics..."
    echo "Resource Group: $resourceGroup"
    echo "NetApp Account: $netAppAccount"
    echo "Volume: $volumeName"
    echo ""
    
    check_anf_volume
    check_network_connectivity  
    check_export_policies
    check_performance
    avs_guidance
}

# Command line options
case "${1:-all}" in
    "volume")
        check_anf_volume
        ;;
    "network")
        check_network_connectivity
        ;;
    "export")
        check_export_policies
        ;;
    "performance")
        check_performance
        ;;
    "guidance")
        avs_guidance
        ;;
    "all"|*)
        run_all_checks
        ;;
esac

echo ""
echo "🏁 Troubleshooting complete!"
echo "For additional help, check Azure NetApp Files and AVS documentation."
