#!/bin/bash
# Azure NetApp Files LDAP User Access Troubleshooting Script
# Based on Microsoft Learn LDAP troubleshooting documentation
# Diagnoses LDAP authentication and user access issues

# Variables (customize these)
resourceGroup="your-anf-rg"
netAppAccount="your-anf-account"
capacityPool="your-pool"
volumeName="your-volume"
testUsername=""  # Username to test LDAP access
subscriptionId=""  # Will be detected automatically if empty

echo "📚 Azure NetApp Files LDAP User Access Troubleshooting"
echo "====================================================="

# Function to detect subscription ID
detect_subscription() {
    if [ -z "$subscriptionId" ]; then
        echo "🔍 Detecting subscription ID..."
        subscriptionId=$(az account show --query id -o tsv 2>/dev/null)
        echo "📍 Using subscription: $subscriptionId"
    fi
}

# Function to check LDAP-enabled volume configuration
check_ldap_volume_config() {
    echo ""
    echo "📋 Checking LDAP volume configuration..."
    
    volume_info=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "{Name:name,ProtocolTypes:protocolTypes,LdapEnabled:ldapEnabled,State:provisioningState,UnixPermissions:unixPermissions,HasRootAccess:hasRootAccess}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Volume configuration found:"
        echo "$volume_info" | jq .
        
        # Extract key information
        protocol_types=$(echo "$volume_info" | jq -r '.ProtocolTypes[]' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        ldap_enabled=$(echo "$volume_info" | jq -r '.LdapEnabled // false')
        volume_state=$(echo "$volume_info" | jq -r '.State')
        unix_permissions=$(echo "$volume_info" | jq -r '.UnixPermissions // "0755"')
        has_root_access=$(echo "$volume_info" | jq -r '.HasRootAccess // false')
        
        echo ""
        echo "🎯 LDAP Configuration Analysis:"
        echo "   Protocol Types: $protocol_types"
        echo "   LDAP Enabled: $ldap_enabled"
        echo "   Volume State: $volume_state"
        echo "   Unix Permissions: $unix_permissions"
        echo "   Root Access: $has_root_access"
        
        # Check for documented error: LDAP with SMB
        if echo "$protocol_types" | grep -q "CIFS" && [ "$ldap_enabled" = "true" ]; then
            echo "❌ DOCUMENTED ERROR: LDAP enabled with SMB volume"
            echo "   Error: 'ldapEnabled option is only supported with NFS protocol volume'"
            echo "   Solution: LDAP can only be used with NFS volumes"
            return 1
        fi
        
        # Check if LDAP is properly enabled for NFS
        if echo "$protocol_types" | grep -q "NFS" && [ "$ldap_enabled" = "true" ]; then
            echo "✅ LDAP properly enabled for NFS volume"
        elif echo "$protocol_types" | grep -q "NFS" && [ "$ldap_enabled" = "false" ]; then
            echo "⚠️ NFS volume with LDAP disabled"
            echo "   User access will be based on export policy only"
        else
            echo "❌ Invalid configuration detected"
            return 1
        fi
        
        return 0
    else
        echo "❌ Could not retrieve volume information"
        return 1
    fi
}

# Function to check Active Directory LDAP configuration
check_ad_ldap_config() {
    echo ""
    echo "🏢 Checking Active Directory LDAP configuration..."
    
    ad_config=$(az netappfiles account ad list \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --query "[].{Domain:domain,DNS:dns,LdapSigning:ldapSigning,LdapOverTLS:ldapOverTLS,AllowLocalNfsUsersWithLdap:allowLocalNfsUsersWithLdap,LdapSearchScope:ldapSearchScope,PreferredServersForLdapClient:preferredServersForLdapClient}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$ad_config" != "[]" ]; then
        echo "✅ Active Directory LDAP configuration found:"
        echo "$ad_config" | jq .
        
        # Extract key LDAP information
        domain=$(echo "$ad_config" | jq -r '.[0].Domain')
        dns_servers=$(echo "$ad_config" | jq -r '.[0].DNS')
        ldap_signing=$(echo "$ad_config" | jq -r '.[0].LdapSigning // false')
        ldap_over_tls=$(echo "$ad_config" | jq -r '.[0].LdapOverTLS // false')
        allow_local_nfs_users=$(echo "$ad_config" | jq -r '.[0].AllowLocalNfsUsersWithLdap // false')
        ldap_search_scope=$(echo "$ad_config" | jq -r '.[0].LdapSearchScope // null')
        preferred_servers=$(echo "$ad_config" | jq -r '.[0].PreferredServersForLdapClient // null')
        
        echo ""
        echo "🎯 LDAP Configuration Summary:"
        echo "   Domain: $domain"
        echo "   DNS Servers: $dns_servers"
        echo "   LDAP Signing: $ldap_signing"
        echo "   LDAP over TLS: $ldap_over_tls"
        echo "   Allow Local NFS Users: $allow_local_nfs_users"
        echo "   LDAP Search Scope: $ldap_search_scope"
        echo "   Preferred LDAP Servers: $preferred_servers"
        
        # Analyze configuration for common issues
        if [ "$ldap_search_scope" = "null" ] || [ -z "$ldap_search_scope" ]; then
            echo "⚠️ LDAP Search Scope not configured"
            echo "   May cause query timeouts when only primary group IDs are seen"
        fi
        
        if [ "$preferred_servers" = "null" ] || [ -z "$preferred_servers" ]; then
            echo "⚠️ Preferred LDAP servers not configured"
            echo "   May cause query timeouts with auxiliary groups"
        fi
        
        return 0
    else
        echo "❌ No Active Directory LDAP configuration found"
        echo "   LDAP volumes require Active Directory connection"
        return 1
    fi
}

# Function to test LDAP connectivity and authentication
test_ldap_connectivity() {
    echo ""
    echo "📚 Testing LDAP connectivity and authentication..."
    
    if [ -z "$dns_servers" ]; then
        echo "❌ DNS servers not available for LDAP test"
        return 1
    fi
    
    # Parse DNS servers (typically domain controllers with LDAP)
    IFS=',' read -ra DNS_ARRAY <<< "$dns_servers"
    
    for ldap_server in "${DNS_ARRAY[@]}"; do
        ldap_server=$(echo "$ldap_server" | tr -d ' ')
        echo ""
        echo "🔍 Testing LDAP server: $ldap_server"
        
        # Test LDAP port 389
        if timeout 5 bash -c "</dev/tcp/$ldap_server/389" 2>/dev/null; then
            echo "  ✅ LDAP port 389 accessible"
        else
            echo "  ❌ DOCUMENTED ERROR: LDAP port 389 not accessible"
            echo "     Error: 'Could not query DNS server'"
            echo "     Solution: Check NSG rules allow LDAP traffic"
        fi
        
        # Test LDAPS port 636 (if LDAP over TLS enabled)
        if [ "$ldap_over_tls" = "true" ]; then
            if timeout 5 bash -c "</dev/tcp/$ldap_server/636" 2>/dev/null; then
                echo "  ✅ LDAPS port 636 accessible"
            else
                echo "  ❌ LDAPS port 636 not accessible"
                echo "     Required for LDAP over TLS"
            fi
        fi
        
        # Test Global Catalog LDAP port 3268
        if timeout 5 bash -c "</dev/tcp/$ldap_server/3268" 2>/dev/null; then
            echo "  ✅ Global Catalog LDAP port 3268 accessible"
        else
            echo "  ⚠️ Global Catalog LDAP port 3268 not accessible"
            echo "     May limit cross-domain user lookups"
        fi
    done
    
    # Test LDAP query if ldapsearch is available
    if command -v ldapsearch >/dev/null 2>&1; then
        echo ""
        echo "🔍 Testing LDAP query functionality..."
        
        if [ -n "$testUsername" ]; then
            ldap_base="DC=$(echo "$domain" | sed 's/\./,DC=/g')"
            echo "Testing LDAP search for user: $testUsername"
            echo "Base DN: $ldap_base"
            
            # Attempt anonymous LDAP search
            ldap_result=$(ldapsearch -H "ldap://${dns_servers%,*}" -x -b "$ldap_base" "(sAMAccountName=$testUsername)" dn 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$ldap_result" ]; then
                echo "✅ LDAP user search successful"
                echo "$ldap_result" | grep "^dn:"
            else
                echo "❌ DOCUMENTED ERROR: LDAP user search failed"
                echo "   Error: 'Entry doesn't exist for username'"
                echo "   Possible causes:"
                echo "   • User not present on LDAP server"
                echo "   • LDAP server not healthy"
                echo "   • Anonymous bind not allowed"
            fi
        else
            echo "⚠️ No test username provided"
            echo "   Set testUsername variable to test specific user"
        fi
    else
        echo "⚠️ ldapsearch not available"
        echo "   Install openldap-clients package to test LDAP queries"
    fi
}

# Function to check documented LDAP errors
check_documented_ldap_errors() {
    echo ""
    echo "📚 Microsoft Learn Documented LDAP Error Patterns"
    echo "================================================"
    echo ""
    echo "🔍 Common LDAP Volume Errors:"
    echo ""
    echo "1. Protocol Restriction Error:"
    echo "   Error: 'ldapEnabled option is only supported with NFS protocol volume'"
    echo "   Cause: Attempting to create SMB volume with LDAP enabled"
    echo "   Solution: Create SMB volumes with LDAP disabled, use LDAP only with NFS"
    echo ""
    echo "2. Configuration Update Error:"
    echo "   Error: 'ldapEnabled parameter is not allowed to update'"
    echo "   Cause: Trying to modify LDAP setting after volume creation"
    echo "   Solution: Cannot change LDAP setting post-creation, must recreate volume"
    echo ""
    echo "3. DNS Resolution Error:"
    echo "   Error: 'Could not query DNS server'"
    echo "   Causes:"
    echo "   • DNS server unreachable from ANF subnet"
    echo "   • Incorrect DNS IP in AD connection"
    echo "   • Network issues or NSG blocking DNS traffic"
    echo "   • AD and volume in different regions (Basic network features)"
    echo "   Solutions:"
    echo "   • Verify DNS IP addresses are correct"
    echo "   • Check NSG rules allow port 53"
    echo "   • Ensure VNet peering if AD and volume in different VNets"
    echo "   • Use same region for AD and volume with Basic network features"
    echo ""
    echo "4. Snapshot Compatibility Error:"
    echo "   Error: 'Aggregate does not exist'"
    echo "   Cause: Creating LDAP-enabled volume from LDAP-disabled snapshot"
    echo "   Solution: Create LDAP-disabled volume from LDAP-disabled snapshot"
    echo ""
    echo "5. Group Membership Issues:"
    echo "   Error: 'When only primary group IDs are seen and user belongs to auxiliary groups'"
    echo "   Cause: LDAP query timeout"
    echo "   Solutions:"
    echo "   • Configure LDAP search scope option"
    echo "   • Use preferred Active Directory servers for LDAP client"
    echo ""
    echo "6. User Lookup Failures:"
    echo "   Error: 'Entry doesn't exist for username'"
    echo "   Causes:"
    echo "   • User not present on LDAP server"
    echo "   • LDAP server unhealthy or unreachable"
    echo "   • Incorrect search base configuration"
    echo "   Solutions:"
    echo "   • Verify user exists in Active Directory"
    echo "   • Check LDAP server health and connectivity"
    echo "   • Validate LDAP search base configuration"
}

# Function to provide LDAP optimization recommendations
ldap_optimization_recommendations() {
    echo ""
    echo "💡 LDAP Performance and Reliability Recommendations"
    echo "================================================="
    echo ""
    echo "🚀 Performance Optimizations:"
    echo ""
    echo "1. Configure LDAP Search Scope:"
    echo "   • Reduces query timeouts"
    echo "   • Improves auxiliary group resolution"
    echo "   • Command: az netappfiles account ad update --ldap-search-scope \\"
    echo "     \"CN=Users,DC=contoso,DC=com\""
    echo ""
    echo "2. Use Preferred LDAP Servers:"
    echo "   • Reduces latency and timeouts"
    echo "   • Improves query reliability"
    echo "   • Command: az netappfiles account ad update --preferred-servers-for-ldap-client \\"
    echo "     \"10.1.1.4,10.1.1.5\""
    echo ""
    echo "3. Enable LDAP Signing:"
    echo "   • Improves security"
    echo "   • Required by some AD configurations"
    echo "   • Command: az netappfiles account ad update --ldap-signing true"
    echo ""
    echo "4. Configure LDAP over TLS:"
    echo "   • Encrypts LDAP communication"
    echo "   • Requires root CA certificate upload"
    echo "   • Command: az netappfiles account ad update --ldap-over-tls true"
    echo ""
    echo "🔧 Troubleshooting Tools:"
    echo ""
    echo "1. Test LDAP User Resolution:"
    echo "   ldapsearch -H ldap://\$LDAP_SERVER -x -b \"DC=domain,DC=com\" \\"
    echo "   \"(sAMAccountName=\$USERNAME)\" memberOf"
    echo ""
    echo "2. Check Group Membership:"
    echo "   ldapsearch -H ldap://\$LDAP_SERVER -x -b \"DC=domain,DC=com\" \\"
    echo "   \"(sAMAccountName=\$USERNAME)\" memberOf"
    echo ""
    echo "3. Verify LDAP Server Health:"
    echo "   ldapsearch -H ldap://\$LDAP_SERVER -x -s base"
    echo ""
    echo "4. Test LDAPS Connection:"
    echo "   ldapsearch -H ldaps://\$LDAP_SERVER -x -s base"
    echo ""
    echo "📊 Monitoring and Diagnostics:"
    echo ""
    echo "1. Monitor LDAP Query Performance:"
    echo "   • Check for query timeouts in AD logs"
    echo "   • Monitor network latency to LDAP servers"
    echo "   • Review LDAP search scope efficiency"
    echo ""
    echo "2. Common Performance Issues:"
    echo "   • Large groups causing query timeouts"
    echo "   • Inefficient LDAP search scope"
    echo "   • High network latency to LDAP servers"
    echo "   • LDAP server overload"
    echo ""
    echo "🔄 Volume Creation Commands:"
    echo ""
    echo "Create LDAP-enabled NFS volume:"
    echo "az netappfiles volume create \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --name $volumeName \\"
    echo "  --location \"\$(az group show -n $resourceGroup --query location -o tsv)\" \\"
    echo "  --service-level Premium \\"
    echo "  --usage-threshold 107374182400 \\"
    echo "  --vnet \"your-vnet\" \\"
    echo "  --subnet \"your-subnet\" \\"
    echo "  --creation-token \"ldap-nfs-volume\" \\"
    echo "  --protocol-types NFSv3 \\"
    echo "  --ldap-enabled true"
}

# Function to test user access scenarios
test_user_access_scenarios() {
    echo ""
    echo "👤 User Access Testing Scenarios"
    echo "==============================="
    echo ""
    echo "🧪 Manual Testing Procedures:"
    echo ""
    echo "1. Test Local User Access (if allowLocalNfsUsersWithLdap=true):"
    echo "   • Mount volume as local user"
    echo "   • Create/read files with local UID/GID"
    echo "   • Verify access works without LDAP lookup"
    echo ""
    echo "2. Test LDAP User Access:"
    echo "   • Mount volume as LDAP-authenticated user"
    echo "   • Verify user ID resolution via LDAP"
    echo "   • Test group membership inheritance"
    echo ""
    echo "3. Test Mixed Access (Local + LDAP):"
    echo "   • Verify both local and LDAP users can access"
    echo "   • Check file ownership and permissions"
    echo "   • Test group access scenarios"
    echo ""
    echo "4. Test Auxiliary Group Access:"
    echo "   • User with multiple group memberships"
    echo "   • Verify all groups are resolved"
    echo "   • Check for query timeout issues"
    echo ""
    echo "📋 Verification Commands:"
    echo ""
    echo "Check user ID resolution:"
    echo "id \$USERNAME"
    echo ""
    echo "Check group memberships:"
    echo "groups \$USERNAME"
    echo ""
    echo "Test file access:"
    echo "sudo -u \$USERNAME touch /mnt/anf/test_file"
    echo "ls -la /mnt/anf/test_file"
    echo ""
    echo "Monitor LDAP queries:"
    echo "# On AD server, monitor LDAP query logs"
    echo "# Check for query timeouts or failures"
}

# Main execution
detect_subscription

echo "Starting comprehensive LDAP user access troubleshooting..."
echo "Based on Microsoft Learn LDAP troubleshooting documentation"
echo ""

if check_ldap_volume_config; then
    if check_ad_ldap_config; then
        test_ldap_connectivity
        test_user_access_scenarios
    fi
    
    check_documented_ldap_errors
    ldap_optimization_recommendations
else
    echo ""
    echo "❌ Volume configuration issues detected"
    echo ""
    echo "🔧 To create LDAP-enabled NFS volume:"
    echo "az netappfiles volume create \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --name $volumeName \\"
    echo "  --location \"\$(az group show -n $resourceGroup --query location -o tsv)\" \\"
    echo "  --service-level Premium \\"
    echo "  --usage-threshold 107374182400 \\"
    echo "  --vnet \"your-vnet\" \\"
    echo "  --subnet \"your-subnet\" \\"
    echo "  --creation-token \"ldap-nfs-volume\" \\"
    echo "  --protocol-types NFSv3 \\"
    echo "  --ldap-enabled true"
fi

echo ""
echo "🏁 LDAP user access troubleshooting complete!"
echo "📖 Reference: https://learn.microsoft.com/azure/azure-netapp-files/troubleshoot-user-access-ldap"
