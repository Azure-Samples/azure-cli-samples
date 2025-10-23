#!/bin/bash
# Azure NetApp Files Network Planning and Guidelines Troubleshooting Script
# Based on Microsoft Learn network planning documentation
# Analyzes network configuration and provides planning recommendations

# Variables (customize these)
resourceGroup="your-anf-rg"
netAppAccount="your-anf-account"
capacityPool="your-pool"
volumeName="your-volume"
subscriptionId=""  # Will be detected automatically if empty

echo "🌐 Azure NetApp Files Network Planning & Guidelines Troubleshooting"
echo "=================================================================="

# Function to detect subscription ID
detect_subscription() {
    if [ -z "$subscriptionId" ]; then
        echo "🔍 Detecting subscription ID..."
        subscriptionId=$(az account show --query id -o tsv 2>/dev/null)
        echo "📍 Using subscription: $subscriptionId"
    fi
}

# Function to analyze network features configuration
analyze_network_features() {
    echo ""
    echo "🔧 Analyzing Network Features Configuration..."
    
    volume_info=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "{Name:name,NetworkFeatures:networkFeatures,MountTargets:mountTargets,State:provisioningState}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Volume network configuration found:"
        echo "$volume_info" | jq .
        
        # Extract network information
        network_features=$(echo "$volume_info" | jq -r '.NetworkFeatures // "Basic"')
        mount_targets=$(echo "$volume_info" | jq -r '.MountTargets')
        volume_state=$(echo "$volume_info" | jq -r '.State')
        
        echo ""
        echo "🎯 Network Features Analysis:"
        echo "   Network Features: $network_features"
        echo "   Volume State: $volume_state"
        
        # Get subnet information from mount targets
        if [ "$mount_targets" != "null" ] && [ "$mount_targets" != "[]" ]; then
            subnet_id=$(echo "$mount_targets" | jq -r '.[0].subnet')
            mount_ip=$(echo "$mount_targets" | jq -r '.[0].ipAddress')
            
            echo "   Subnet ID: $subnet_id"
            echo "   Mount IP: $mount_ip"
            
            # Extract subnet details
            subnet_rg=$(echo "$subnet_id" | cut -d'/' -f5)
            vnet_name=$(echo "$subnet_id" | cut -d'/' -f9)
            subnet_name=$(echo "$subnet_id" | cut -d'/' -f11)
            
            echo "   VNet: $vnet_name"
            echo "   Subnet: $subnet_name"
            echo "   Resource Group: $subnet_rg"
        fi
        
        # Analyze network features capabilities
        analyze_network_features_capabilities "$network_features"
        
        return 0
    else
        echo "❌ Could not retrieve volume network information"
        return 1
    fi
}

# Function to analyze network features capabilities
analyze_network_features_capabilities() {
    local features="$1"
    
    echo ""
    echo "📊 Network Features Capabilities Analysis:"
    echo "Current setting: $features"
    echo ""
    
    if [ "$features" = "Standard" ]; then
        echo "✅ Standard Network Features - Full capabilities:"
        echo "   • Same standard IP limits as VMs"
        echo "   • NSG support on delegated subnets"
        echo "   • UDR support on delegated subnets"
        echo "   • Private Endpoints connectivity"
        echo "   • Service Endpoints connectivity"
        echo "   • Cross-region VNet peering"
        echo "   • Traffic routing via NVA from peered VNet"
        echo "   • ExpressRoute FastPath support"
        echo "   • Active/Active VPN gateways"
        echo "   • Virtual WAN (VWAN) connectivity"
        echo ""
    elif [ "$features" = "Basic" ]; then
        echo "⚠️ Basic Network Features - Limited capabilities:"
        echo "   ❌ Limited to 1000 IPs in VNet (including peered VNets)"
        echo "   ❌ No NSG support on delegated subnets"
        echo "   ❌ No UDR support on delegated subnets"
        echo "   ❌ No Private Endpoints connectivity"
        echo "   ❌ No Service Endpoints connectivity"
        echo "   ❌ No cross-region VNet peering"
        echo "   ❌ No ExpressRoute FastPath"
        echo "   ❌ No Active/Active VPN gateways"
        echo "   ❌ No Virtual WAN support"
        echo ""
        echo "🚨 IMPORTANT: Route limit increases no longer approved after May 30, 2025"
        echo "   Microsoft recommendation: Upgrade to Standard network features"
        echo ""
        echo "✅ Basic features support:"
        echo "   • Local VNet connectivity"
        echo "   • Same-region VNet peering"
        echo "   • ExpressRoute/VPN gateway connectivity"
        echo "   • Active/Passive gateways"
    fi
}

# Function to check subnet delegation and configuration
check_subnet_delegation() {
    echo ""
    echo "🏗️ Checking Subnet Delegation and Configuration..."
    
    if [ -z "$subnet_rg" ] || [ -z "$vnet_name" ] || [ -z "$subnet_name" ]; then
        echo "❌ Subnet information not available"
        return 1
    fi
    
    subnet_info=$(az network vnet subnet show \
        --resource-group "$subnet_rg" \
        --vnet-name "$vnet_name" \
        --name "$subnet_name" \
        --query "{AddressPrefix:addressPrefix,Delegations:delegations,NSG:networkSecurityGroup,RouteTable:routeTable}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Subnet configuration found:"
        echo "$subnet_info" | jq .
        
        # Check delegation
        delegation=$(echo "$subnet_info" | jq -r '.Delegations[0].serviceName // "none"')
        address_prefix=$(echo "$subnet_info" | jq -r '.AddressPrefix')
        nsg_id=$(echo "$subnet_info" | jq -r '.NSG.id // "none"')
        route_table_id=$(echo "$subnet_info" | jq -r '.RouteTable.id // "none"')
        
        echo ""
        echo "🎯 Subnet Analysis:"
        echo "   Address Prefix: $address_prefix"
        echo "   Delegation: $delegation"
        echo "   NSG: $(if [ "$nsg_id" != "none" ]; then echo "Attached"; else echo "None"; fi)"
        echo "   Route Table: $(if [ "$route_table_id" != "none" ]; then echo "Attached"; else echo "None"; fi)"
        
        # Validate delegation
        if [ "$delegation" = "Microsoft.NetApp/volumes" ]; then
            echo "✅ Subnet properly delegated to Microsoft.NetApp/volumes"
        else
            echo "❌ CONFIGURATION ERROR: Subnet not properly delegated"
            echo "   Expected: Microsoft.NetApp/volumes"
            echo "   Found: $delegation"
            echo "   Solution: Delegate subnet to Microsoft.NetApp/volumes"
        fi
        
        # Analyze address space
        analyze_subnet_sizing "$address_prefix"
        
        # Check NSG and UDR compatibility
        check_nsg_udr_compatibility "$nsg_id" "$route_table_id"
        
        return 0
    else
        echo "❌ Could not retrieve subnet information"
        return 1
    fi
}

# Function to analyze subnet sizing
analyze_subnet_sizing() {
    local address_prefix="$1"
    
    echo ""
    echo "📏 Subnet Sizing Analysis:"
    echo "Current subnet: $address_prefix"
    
    # Extract CIDR notation
    if [[ $address_prefix =~ /([0-9]+)$ ]]; then
        cidr=${BASH_REMATCH[1]}
        
        case $cidr in
            26)
                echo "✅ /26 subnet (64 IPs) - Recommended for general workloads"
                echo "   Available IPs: ~59 (Azure reserves 5)"
                ;;
            25)
                echo "✅ /25 subnet (128 IPs) - Recommended for SAP workloads"
                echo "   Available IPs: ~123 (Azure reserves 5)"
                ;;
            24)
                echo "✅ /24 subnet (256 IPs) - Good for large deployments"
                echo "   Available IPs: ~251 (Azure reserves 5)"
                ;;
            27)
                echo "⚠️ /27 subnet (32 IPs) - Small subnet"
                echo "   Available IPs: ~27 (Azure reserves 5)"
                echo "   May limit scalability"
                ;;
            28|29|30)
                echo "❌ /$cidr subnet - Too small for ANF"
                echo "   Minimum recommended: /26"
                ;;
            *)
                echo "ℹ️ /$cidr subnet - Custom sizing"
                ;;
        esac
        
        echo ""
        echo "📋 Microsoft Learn Sizing Recommendations:"
        echo "   • SAP workloads: /25 or larger"
        echo "   • Other workloads: /26 or larger"
        echo "   • Consider growth and additional volumes"
    fi
}

# Function to check NSG and UDR compatibility
check_nsg_udr_compatibility() {
    local nsg_id="$1"
    local route_table_id="$2"
    
    echo ""
    echo "🛡️ NSG and UDR Compatibility Check:"
    
    if [ "$network_features" = "Standard" ]; then
        echo "✅ Standard network features - NSG and UDR supported"
        
        if [ "$nsg_id" != "none" ]; then
            echo "✅ NSG attached and supported"
            check_nsg_rules "$nsg_id"
        else
            echo "ℹ️ No NSG attached (optional with Standard features)"
        fi
        
        if [ "$route_table_id" != "none" ]; then
            echo "✅ UDR attached and supported"
            check_udr_rules "$route_table_id"
        else
            echo "ℹ️ No UDR attached (optional with Standard features)"
        fi
        
    elif [ "$network_features" = "Basic" ]; then
        echo "⚠️ Basic network features - Limited NSG/UDR support"
        
        if [ "$nsg_id" != "none" ]; then
            echo "❌ NSG attached but not supported with Basic features"
            echo "   NSG rules will not apply to ANF traffic"
            echo "   Recommendation: Upgrade to Standard network features"
        fi
        
        if [ "$route_table_id" != "none" ]; then
            echo "❌ UDR attached but not supported with Basic features"
            echo "   UDR rules will not apply to ANF traffic"
            echo "   Recommendation: Upgrade to Standard network features"
        fi
    fi
}

# Function to check NSG rules for ANF requirements
check_nsg_rules() {
    local nsg_id="$1"
    
    if [ "$nsg_id" = "none" ] || [ -z "$nsg_id" ]; then
        return 0
    fi
    
    nsg_name=$(echo "$nsg_id" | cut -d'/' -f9)
    nsg_rg=$(echo "$nsg_id" | cut -d'/' -f5)
    
    echo ""
    echo "🔍 Analyzing NSG rules for ANF requirements..."
    echo "NSG: $nsg_name"
    
    # Check for ANF-related port rules
    anf_rules=$(az network nsg rule list \
        --resource-group "$nsg_rg" \
        --nsg-name "$nsg_name" \
        --query "[?destinationPortRange=='2049' || destinationPortRange=='111' || destinationPortRange=='53' || destinationPortRange=='389' || destinationPortRange=='445' || destinationPortRange=='88' || contains(destinationPortRange, '2049') || contains(destinationPortRange, '111')]" \
        -o json 2>/dev/null)
    
    if [ "$anf_rules" != "[]" ] && [ "$anf_rules" != "null" ]; then
        echo "📋 ANF-related NSG rules found:"
        echo "$anf_rules" | jq -r '.[] | "  Priority: \(.priority), Action: \(.access), Port: \(.destinationPortRange), Source: \(.sourceAddressPrefix)"'
    else
        echo "⚠️ No specific ANF port rules found"
        echo "   Required ports for full functionality:"
        echo "   • NFS: 2049, 111"
        echo "   • DNS: 53"
        echo "   • LDAP: 389, 636"
        echo "   • SMB: 445"
        echo "   • Kerberos: 88"
    fi
}

# Function to check UDR rules for ANF
check_udr_rules() {
    local route_table_id="$1"
    
    if [ "$route_table_id" = "none" ] || [ -z "$route_table_id" ]; then
        return 0
    fi
    
    route_table_name=$(echo "$route_table_id" | cut -d'/' -f9)
    route_table_rg=$(echo "$route_table_id" | cut -d'/' -f5)
    
    echo ""
    echo "🛣️ Analyzing UDR rules for ANF..."
    echo "Route Table: $route_table_name"
    
    routes=$(az network route-table route list \
        --resource-group "$route_table_rg" \
        --route-table-name "$route_table_name" \
        --query "[].{Name:name,AddressPrefix:addressPrefix,NextHopType:nextHopType,NextHopIpAddress:nextHopIpAddress}" \
        -o json 2>/dev/null)
    
    if [ "$routes" != "[]" ] && [ "$routes" != "null" ]; then
        echo "📋 Custom routes found:"
        echo "$routes" | jq -r '.[] | "  Route: \(.AddressPrefix) -> \(.NextHopType) (\(.NextHopIpAddress // "N/A"))"'
        
        echo ""
        echo "⚠️ UDR Configuration Guidelines for ANF:"
        echo "   • Route prefix must be more specific or equal to delegated subnet size"
        echo "   • For delegated subnet x.x.x.x/24, UDR must be /24 or more specific (e.g., /32)"
        echo "   • Less specific routes (e.g., /16) will not be effective"
        echo "   • For on-premises via gateway: use /32 route for ANF volume IP"
    else
        echo "ℹ️ No custom routes configured"
    fi
}

# Function to check VNet peering configuration
check_vnet_peering() {
    echo ""
    echo "🔗 Checking VNet Peering Configuration..."
    
    if [ -z "$vnet_name" ] || [ -z "$subnet_rg" ]; then
        echo "❌ VNet information not available"
        return 1
    fi
    
    peerings=$(az network vnet peering list \
        --resource-group "$subnet_rg" \
        --vnet-name "$vnet_name" \
        --query "[].{Name:name,RemoteVnet:remoteVirtualNetwork.id,PeeringState:peeringState,AllowForwardedTraffic:allowForwardedTraffic,AllowGatewayTransit:allowGatewayTransit,UseRemoteGateways:useRemoteGateways}" \
        -o json 2>/dev/null)
    
    if [ "$peerings" != "[]" ] && [ "$peerings" != "null" ]; then
        echo "✅ VNet peerings found:"
        echo "$peerings" | jq .
        
        echo ""
        echo "🎯 Peering Analysis:"
        
        # Analyze each peering
        echo "$peerings" | jq -c '.[]' | while read -r peering; do
            peering_name=$(echo "$peering" | jq -r '.Name')
            peering_state=$(echo "$peering" | jq -r '.PeeringState')
            remote_vnet=$(echo "$peering" | jq -r '.RemoteVnet')
            allow_forwarded=$(echo "$peering" | jq -r '.AllowForwardedTraffic')
            gateway_transit=$(echo "$peering" | jq -r '.AllowGatewayTransit')
            use_remote_gateways=$(echo "$peering" | jq -r '.UseRemoteGateways')
            
            echo "  Peering: $peering_name"
            echo "    State: $peering_state"
            echo "    Remote VNet: $(basename "$remote_vnet")"
            echo "    Allow Forwarded Traffic: $allow_forwarded"
            echo "    Gateway Transit: $gateway_transit"
            echo "    Use Remote Gateways: $use_remote_gateways"
            
            if [ "$peering_state" != "Connected" ]; then
                echo "    ⚠️ Peering not in Connected state"
            fi
        done
        
        echo ""
        echo "📋 VNet Peering Guidelines:"
        echo "   • Cross-region peering requires Standard network features"
        echo "   • Transit routing not supported over VNet peering"
        echo "   • Spoke VNets need direct peering to access each other's ANF volumes"
        echo "   • Gateway transit allows on-premises access via hub VNet"
        
    else
        echo "ℹ️ No VNet peerings configured"
        echo "   ANF volumes accessible only within local VNet"
    fi
}

# Function to provide network planning recommendations
network_planning_recommendations() {
    echo ""
    echo "💡 Network Planning Recommendations (Microsoft Learn)"
    echo "=================================================="
    echo ""
    echo "🏗️ Network Architecture Planning:"
    echo ""
    echo "1. Network Features Selection:"
    echo "   Standard features recommended for:"
    echo "   • Cross-region connectivity requirements"
    echo "   • NSG/UDR requirements on delegated subnet"
    echo "   • Private Endpoints or Service Endpoints"
    echo "   • ExpressRoute FastPath"
    echo "   • Virtual WAN connectivity"
    echo ""
    echo "   Basic features suitable for:"
    echo "   • Simple, same-region deployments"
    echo "   • Limited IP requirements (<1000 IPs)"
    echo "   • Cost-optimized scenarios"
    echo "   ⚠️ Note: Route limit increases no longer approved after May 30, 2025"
    echo ""
    echo "2. Subnet Planning:"
    echo "   • Minimum /26 for general workloads"
    echo "   • Minimum /25 for SAP workloads"
    echo "   • One delegated subnet per VNet"
    echo "   • Cannot expand VNet address space with existing peering"
    echo ""
    echo "3. VNet Peering Strategy:"
    echo "   • Hub-spoke topology for centralized connectivity"
    echo "   • Direct peering required between spoke VNets for ANF access"
    echo "   • No transit routing through hub VNet"
    echo "   • Cross-region peering requires Standard network features"
    echo ""
    echo "4. Hybrid Connectivity:"
    echo "   • ExpressRoute or VPN gateway for on-premises access"
    echo "   • Gateway transit configuration for spoke VNet access"
    echo "   • UDR configuration for traffic routing via NVA"
    echo "   • Ensure ANF traffic reaches correct gateways"
    echo ""
    echo "🔧 Configuration Commands:"
    echo ""
    echo "Upgrade to Standard network features:"
    echo "az netappfiles volume update \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --name $volumeName \\"
    echo "  --network-features Standard"
    echo ""
    echo "Delegate subnet to ANF:"
    echo "az network vnet subnet update \\"
    echo "  --resource-group \$VNET_RG \\"
    echo "  --vnet-name \$VNET_NAME \\"
    echo "  --name \$SUBNET_NAME \\"
    echo "  --delegations Microsoft.NetApp/volumes"
    echo ""
    echo "Configure VNet peering with gateway transit:"
    echo "az network vnet peering create \\"
    echo "  --resource-group \$HUB_RG \\"
    echo "  --vnet-name \$HUB_VNET \\"
    echo "  --name hub-to-spoke \\"
    echo "  --remote-vnet \$SPOKE_VNET_ID \\"
    echo "  --allow-gateway-transit true"
}

# Function to check documented network errors
check_documented_network_errors() {
    echo ""
    echo "📚 Common Network Configuration Errors"
    echo "===================================="
    echo ""
    echo "🔍 Microsoft Learn Documented Issues:"
    echo ""
    echo "1. Allocation Errors:"
    echo "   Error: 'No storage available with Standard network features'"
    echo "   Solutions:"
    echo "   • Try different VNet to avoid networking limits"
    echo "   • Use Basic network features if Standard not required"
    echo "   • Retry after some time"
    echo ""
    echo "2. Network Features Constraints:"
    echo "   Basic Features Limitations:"
    echo "   • 1000 IP limit in VNet (including peered VNets)"
    echo "   • No NSG support on delegated subnets"
    echo "   • No UDR support on delegated subnets"
    echo "   • No cross-region VNet peering"
    echo "   • Route limit increases no longer approved"
    echo ""
    echo "3. Subnet Delegation Issues:"
    echo "   • Subnet must be delegated to Microsoft.NetApp/volumes"
    echo "   • One delegated subnet per VNet"
    echo "   • Subnet must be empty before delegation"
    echo "   • Cannot change delegation after ANF deployment"
    echo ""
    echo "4. VNet Peering Limitations:"
    echo "   • Cannot expand VNet address space with existing peering"
    echo "   • Transit routing not supported"
    echo "   • Cross-region peering requires Standard features"
    echo "   • Spoke-to-spoke communication needs direct peering"
    echo ""
    echo "5. UDR Configuration Errors:"
    echo "   • Route prefix must be specific enough for ANF subnet"
    echo "   • On-premises access requires /32 routes for ANF IPs"
    echo "   • Less specific routes may not affect ANF traffic"
    echo "   • NVA routing requires Standard network features"
}

# Main execution
detect_subscription

echo "Starting comprehensive network planning and guidelines analysis..."
echo "Based on Microsoft Learn network planning documentation"
echo ""

if analyze_network_features; then
    check_subnet_delegation
    check_vnet_peering
    network_planning_recommendations
fi

check_documented_network_errors

echo ""
echo "🏁 Network planning and guidelines analysis complete!"
echo "📖 Reference: https://learn.microsoft.com/azure/azure-netapp-files/azure-netapp-files-network-topologies"
