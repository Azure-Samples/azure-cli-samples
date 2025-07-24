#!/bin/bash
# Azure NetApp Files Connectivity Troubleshooting Script
# Diagnoses network connectivity issues between clients and ANF volumes

# Variables (customize these)
resourceGroup="your-anf-rg"
netAppAccount="your-anf-account"
capacityPool="your-pool"
volumeName="your-volume"
clientIP=""  # Will be detected automatically if empty

echo "🌐 Azure NetApp Files Connectivity Troubleshooting"
echo "================================================="

# Function to detect client IP
detect_client_ip() {
    if [ -z "$clientIP" ]; then
        echo "🔍 Detecting client IP address..."
        clientIP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Unable to detect")
        echo "📍 Detected client IP: $clientIP"
    fi
}

# Function to get ANF volume information
get_volume_info() {
    echo ""
    echo "📋 Getting ANF volume information..."
    
    volume_info=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "{Name:name,State:provisioningState,MountTargets:mountTargets,ExportPolicy:exportPolicy}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Volume found:"
        echo "$volume_info" | jq .
        
        # Extract mount target IP
        mountIP=$(echo "$volume_info" | jq -r '.MountTargets[0].ipAddress')
        creationToken=$(az netappfiles volume show \
            --resource-group $resourceGroup \
            --account-name $netAppAccount \
            --pool-name $capacityPool \
            --name $volumeName \
            --query "creationToken" -o tsv)
        
        echo ""
        echo "🎯 Mount information:"
        echo "   Mount target IP: $mountIP"
        echo "   Creation token: $creationToken"
        echo "   Mount command: mount -t nfs $mountIP:/$creationToken /mnt/anf"
        
        return 0
    else
        echo "❌ Volume not found. Check resource group, account, pool, and volume names."
        return 1
    fi
}

# Function to test basic network connectivity
test_network_connectivity() {
    echo ""
    echo "🔍 Testing network connectivity to mount target..."
    
    if [ -z "$mountIP" ]; then
        echo "❌ Mount IP not available. Run volume info check first."
        return 1
    fi
    
    # Test ping (may be blocked by ICMP restrictions)
    echo "📡 Testing ICMP (ping)..."
    if ping -c 3 -W 5 "$mountIP" >/dev/null 2>&1; then
        echo "✅ Ping successful to $mountIP"
    else
        echo "⚠️  Ping failed (ICMP may be blocked - this is often normal)"
    fi
    
    # Test NFS port 2049
    echo "📡 Testing NFS port 2049..."
    if timeout 10 bash -c "</dev/tcp/$mountIP/2049" 2>/dev/null; then
        echo "✅ Port 2049 (NFS) is accessible"
    else
        echo "❌ Port 2049 (NFS) is NOT accessible"
        echo "   This indicates a network connectivity issue"
    fi
    
    # Test port 111 (rpcbind)
    echo "📡 Testing RPC port 111..."
    if timeout 10 bash -c "</dev/tcp/$mountIP/111" 2>/dev/null; then
        echo "✅ Port 111 (RPC) is accessible"
    else
        echo "⚠️  Port 111 (RPC) is not accessible"
    fi
}

# Function to check export policies
check_export_policies() {
    echo ""
    echo "🔐 Checking export policies..."
    
    export_policy=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "exportPolicy.rules" -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "📋 Current export policy rules:"
        echo "$export_policy" | jq .
        
        # Check if client IP is allowed
        if [ -n "$clientIP" ] && [ "$clientIP" != "Unable to detect" ]; then
            echo ""
            echo "🔍 Checking if client IP $clientIP is allowed..."
            
            # This is a simplified check - in reality, you'd need to parse CIDR ranges
            allowed=$(echo "$export_policy" | jq -r ".[].allowedClients" | grep -E "0\.0\.0\.0/0|$clientIP" || echo "")
            
            if [ -n "$allowed" ]; then
                echo "✅ Client IP appears to be allowed"
            else
                echo "⚠️  Client IP may not be explicitly allowed"
                echo "   Check export policy rules manually"
            fi
        fi
        
        # Check NFSv3 support
        nfsv3_count=$(echo "$export_policy" | jq '[.[] | select(.nfsv3 == true)] | length')
        if [ "$nfsv3_count" -gt 0 ]; then
            echo "✅ NFSv3 is enabled"
        else
            echo "❌ NFSv3 is not enabled in any export rule"
        fi
        
        # Check if any rules allow read/write
        rw_count=$(echo "$export_policy" | jq '[.[] | select(.ruleIndex != null and .unixReadWrite == true)] | length')
        if [ "$rw_count" -gt 0 ]; then
            echo "✅ Read/write access is configured"
        else
            echo "⚠️  No read/write access rules found"
        fi
    else
        echo "❌ Could not retrieve export policy"
    fi
}

# Function to check subnet and NSG rules
check_network_security() {
    echo ""
    echo "🛡️  Checking network security configuration..."
    
    # Get volume subnet information
    subnet_info=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "mountTargets[0].subnet" -o tsv 2>/dev/null)
    
    if [ -n "$subnet_info" ]; then
        echo "📍 Volume subnet: $subnet_info"
        
        # Extract subnet name and VNet from the subnet ID
        subnet_name=$(echo "$subnet_info" | cut -d'/' -f11)
        vnet_name=$(echo "$subnet_info" | cut -d'/' -f9)
        subnet_rg=$(echo "$subnet_info" | cut -d'/' -f5)
        
        echo "   Subnet name: $subnet_name"
        echo "   VNet name: $vnet_name"
        echo "   Resource group: $subnet_rg"
        
        # Check if subnet is properly delegated
        echo ""
        echo "🔍 Checking subnet delegation..."
        delegation=$(az network vnet subnet show \
            --resource-group "$subnet_rg" \
            --vnet-name "$vnet_name" \
            --name "$subnet_name" \
            --query "delegations[0].serviceName" -o tsv 2>/dev/null)
        
        if [ "$delegation" = "Microsoft.NetApp/volumes" ]; then
            echo "✅ Subnet is properly delegated to Microsoft.NetApp/volumes"
        else
            echo "❌ Subnet is not properly delegated (found: $delegation)"
        fi
        
        # Check NSG rules
        echo ""
        echo "🔍 Checking Network Security Group rules..."
        nsg_id=$(az network vnet subnet show \
            --resource-group "$subnet_rg" \
            --vnet-name "$vnet_name" \
            --name "$subnet_name" \
            --query "networkSecurityGroup.id" -o tsv 2>/dev/null)
        
        if [ -n "$nsg_id" ] && [ "$nsg_id" != "null" ]; then
            nsg_name=$(echo "$nsg_id" | cut -d'/' -f9)
            nsg_rg=$(echo "$nsg_id" | cut -d'/' -f5)
            
            echo "🛡️  NSG found: $nsg_name"
            
            # Check for NFS-related rules
            nfs_rules=$(az network nsg rule list \
                --resource-group "$nsg_rg" \
                --nsg-name "$nsg_name" \
                --query "[?destinationPortRange=='2049' || destinationPortRange=='111' || destinationPortRange=='*']" \
                -o table 2>/dev/null)
            
            if [ -n "$nfs_rules" ]; then
                echo "📋 NFS-related NSG rules found:"
                echo "$nfs_rules"
            else
                echo "⚠️  No explicit NFS rules found in NSG"
                echo "   Default rules may apply"
            fi
        else
            echo "ℹ️  No NSG attached to subnet"
        fi
    else
        echo "❌ Could not retrieve subnet information"
    fi
}

# Function to test mount command
test_mount() {
    echo ""
    echo "🔧 Testing mount command..."
    
    if [ -z "$mountIP" ] || [ -z "$creationToken" ]; then
        echo "❌ Mount information not available"
        return 1
    fi
    
    # Create temporary mount point
    temp_mount="/tmp/anf_test_mount_$$"
    mkdir -p "$temp_mount"
    
    echo "📁 Created temporary mount point: $temp_mount"
    echo "🔄 Attempting to mount $mountIP:/$creationToken..."
    
    # Try to mount (with timeout)
    timeout 30 mount -t nfs -o rsize=1048576,wsize=1048576,hard,intr,vers=3 \
        "$mountIP:/$creationToken" "$temp_mount" 2>&1
    
    mount_result=$?
    
    if [ $mount_result -eq 0 ]; then
        echo "✅ Mount successful!"
        
        # Test basic operations
        echo "🧪 Testing basic operations..."
        
        # Test write
        if echo "test" > "$temp_mount/connectivity_test.txt" 2>/dev/null; then
            echo "✅ Write test successful"
            rm -f "$temp_mount/connectivity_test.txt" 2>/dev/null
        else
            echo "⚠️  Write test failed (may be read-only)"
        fi
        
        # Test read
        if ls "$temp_mount" >/dev/null 2>&1; then
            echo "✅ Read test successful"
        else
            echo "❌ Read test failed"
        fi
        
        # Unmount
        umount "$temp_mount" 2>/dev/null
        echo "🔄 Unmounted test volume"
    else
        echo "❌ Mount failed (exit code: $mount_result)"
        echo "   Common causes:"
        echo "   • Network connectivity issues"
        echo "   • Export policy restrictions"
        echo "   • NSG blocking NFS traffic"
        echo "   • Volume not ready"
    fi
    
    # Cleanup
    rmdir "$temp_mount" 2>/dev/null
}

# Function to check for common Microsoft Learn documented errors
check_documented_errors() {
    echo ""
    echo "🔍 Checking for Common Documented Errors..."
    
    # Check for DNS query errors
    echo ""
    echo "📡 DNS Query Error Check:"
    echo "Error: 'Could not query DNS server. Verify that the network configuration is correct and that DNS servers are available.'"
    echo "Solutions:"
    echo "  • Check if DNS servers are reachable from ANF subnet"
    echo "  • Verify NSGs allow DNS traffic (port 53)"
    echo "  • Ensure AD DS and volume are in same region (Basic network features)"
    echo "  • Check VNet peering if AD and volume are in different VNets"
    
    # Check for volume state issues
    volume_state=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "provisioningState" -o tsv 2>/dev/null)
    
    echo ""
    echo "📊 Volume State Check:"
    echo "Current volume state: $volume_state"
    if [ "$volume_state" != "Succeeded" ]; then
        echo "⚠️ Volume is not in terminal 'Succeeded' state"
        echo "   Wait for volume operations to complete before mounting"
        echo "   CRUD operations will fail on non-terminal state volumes"
    else
        echo "✅ Volume is in 'Succeeded' state"
    fi
    
    # Check for allocation errors
    echo ""
    echo "💾 Storage Allocation Check:"
    echo "Common allocation errors:"
    echo "  • 'There was a problem locating storage for the volume'"
    echo "  • 'There are currently insufficient resources available'"
    echo "  • 'No storage available with Standard network features'"
    echo "Solutions:"
    echo "  • Retry after some time"
    echo "  • Try different VNet if using Standard network features"
    echo "  • Consider Basic network features if Standard not required"
    
    # Check network features
    network_features=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "networkFeatures" -o tsv 2>/dev/null)
    
    echo ""
    echo "🌐 Network Features: $network_features"
    if [ "$network_features" = "Basic" ]; then
        echo "⚠️ Using Basic network features - limitations apply:"
        echo "   • Maximum 1000 IPs in VNet"
        echo "   • No NSG/UDR support on delegated subnet"
        echo "   • No cross-region VNet peering support"
        echo "   • Route limit increases no longer approved after May 30, 2025"
    fi
}

# Function to provide troubleshooting recommendations
troubleshooting_recommendations() {
    echo ""
    echo "💡 Troubleshooting Recommendations (Microsoft Learn Based)"
    echo "========================================================"
    echo ""
    echo "📋 Common Error Patterns and Solutions:"
    echo ""
    echo "1. 🔐 Export Policy Issues:"
    echo "   • Ensure client IP/subnet is in allowedClients"
    echo "   • Verify NFSv3 is enabled"
    echo "   • Check read/write permissions"
    echo ""
    echo "2. 🌐 Network Issues:"
    echo "   Error: 'Could not query DNS server'"
    echo "   Solutions:"
    echo "   • Verify port 2049 (NFS) is open"
    echo "   • Check NSG rules allow NFS traffic"
    echo "   • Ensure subnet is delegated to Microsoft.NetApp/volumes"
    echo "   • Verify DNS servers are reachable (port 53)"
    echo "   • Check VNet peering configuration"
    echo ""
    echo "3. 🔧 Client Configuration:"
    echo "   • Install nfs-utils package"
    echo "   • Try different NFS versions (NFSv3, NFSv4.1)"
    echo "   • Adjust mount options (rsize, wsize)"
    echo ""
    echo "4. 📊 Volume Status Issues:"
    echo "   • Verify volume is in 'Succeeded' state"
    echo "   • Wait for CRUD operations to complete"
    echo "   • Check volume has mount targets"
    echo "   • Ensure capacity pool has sufficient space"
    echo ""
    echo "5. 💾 Allocation Errors:"
    echo "   Error: 'insufficient resources available'"
    echo "   Solutions:"
    echo "   • Retry operation after some time"
    echo "   • Try different VNet for Standard network features"
    echo "   • Consider Basic network features if Standard not required"
    echo ""
    echo "6. 🎯 Network Features Considerations:"
    echo "   • Standard: Higher limits, NSG/UDR support, cross-region peering"
    echo "   • Basic: 1000 IP limit, no NSG/UDR support, same-region only"
    echo ""
    echo "Example mount commands to try:"
    echo "mount -t nfs -o vers=3 $mountIP:/$creationToken /mnt/anf"
    echo "mount -t nfs -o vers=4.1 $mountIP:/$creationToken /mnt/anf"
    echo "mount -t nfs -o rsize=65536,wsize=65536,vers=3 $mountIP:/$creationToken /mnt/anf"
}

# Main execution
detect_client_ip

if get_volume_info; then
    test_network_connectivity
    check_export_policies
    check_network_security
    check_documented_errors
    
    echo ""
    read -p "Would you like to test mounting the volume? (y/n): " test_mount_choice
    if [[ $test_mount_choice =~ ^[Yy]$ ]]; then
        test_mount
    fi
    
    troubleshooting_recommendations
else
    echo "❌ Cannot proceed without valid volume information"
    exit 1
fi

echo ""
echo "🏁 Connectivity troubleshooting complete!"
echo "For additional help, check Azure NetApp Files documentation."
