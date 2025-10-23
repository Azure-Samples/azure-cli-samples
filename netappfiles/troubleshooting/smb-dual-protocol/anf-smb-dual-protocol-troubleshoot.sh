#!/bin/bash
# Azure NetApp Files SMB and Dual-Protocol Troubleshooting Script
# Based on Microsoft Learn troubleshooting documentation
# Diagnoses SMB and dual-protocol volume creation and access issues

# Variables (customize these)
resourceGroup="your-anf-rg"
netAppAccount="your-anf-account"
capacityPool="your-pool"
volumeName="your-volume"
subscriptionId=""  # Will be detected automatically if empty

echo "📁 Azure NetApp Files SMB & Dual-Protocol Troubleshooting"
echo "========================================================="

# Function to detect subscription ID
detect_subscription() {
    if [ -z "$subscriptionId" ]; then
        echo "🔍 Detecting subscription ID..."
        subscriptionId=$(az account show --query id -o tsv 2>/dev/null)
        echo "📍 Using subscription: $subscriptionId"
    fi
}

# Function to check SMB/dual-protocol volume configuration
check_smb_volume_config() {
    echo ""
    echo "📋 Checking SMB/Dual-Protocol volume configuration..."
    
    volume_info=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "{Name:name,ProtocolTypes:protocolTypes,State:provisioningState,SmbEncryption:smbEncryption,LdapEnabled:ldapEnabled,KerberosEnabled:kerberosEnabled}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Volume configuration found:"
        echo "$volume_info" | jq .
        
        # Extract key information
        protocol_types=$(echo "$volume_info" | jq -r '.ProtocolTypes[]' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        volume_state=$(echo "$volume_info" | jq -r '.State')
        smb_encryption=$(echo "$volume_info" | jq -r '.SmbEncryption // false')
        ldap_enabled=$(echo "$volume_info" | jq -r '.LdapEnabled // false')
        kerberos_enabled=$(echo "$volume_info" | jq -r '.KerberosEnabled // false')
        
        echo ""
        echo "🎯 Configuration Analysis:"
        echo "   Protocol Types: $protocol_types"
        echo "   Volume State: $volume_state"
        echo "   SMB Encryption: $smb_encryption"
        echo "   LDAP Enabled: $ldap_enabled"
        echo "   Kerberos Enabled: $kerberos_enabled"
        
        # Check for documented error: LDAP with SMB
        if echo "$protocol_types" | grep -q "CIFS" && [ "$ldap_enabled" = "true" ]; then
            echo "❌ DOCUMENTED ERROR: LDAP enabled with SMB volume"
            echo "   Error: 'ldapEnabled option is only supported with NFS protocol volume'"
            echo "   Solution: Create SMB volumes with LDAP disabled"
            echo "   Action: Set ldapEnabled to false for SMB volumes"
        fi
        
        # Determine volume type
        if echo "$protocol_types" | grep -q "CIFS" && echo "$protocol_types" | grep -q "NFSv"; then
            echo "✅ Dual-protocol volume detected (SMB + NFS)"
            is_dual_protocol=true
        elif echo "$protocol_types" | grep -q "CIFS"; then
            echo "✅ SMB-only volume detected"
            is_dual_protocol=false
        else
            echo "⚠️ No SMB protocol detected in volume"
            is_dual_protocol=false
        fi
        
        return 0
    else
        echo "❌ Could not retrieve volume information"
        return 1
    fi
}

# Function to check Active Directory configuration for SMB
check_ad_configuration() {
    echo ""
    echo "🏢 Checking Active Directory configuration for SMB..."
    
    ad_config=$(az netappfiles account ad list \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --query "[].{Domain:domain,Username:username,SmbServerName:smbServerName,OrganizationalUnit:organizationalUnit,DNS:dns,LdapSigning:ldapSigning,LdapOverTLS:ldapOverTLS,AesEncryption:aesEncryption}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$ad_config" != "[]" ]; then
        echo "✅ Active Directory configuration found:"
        echo "$ad_config" | jq .
        
        # Extract key information
        domain=$(echo "$ad_config" | jq -r '.[0].Domain')
        username=$(echo "$ad_config" | jq -r '.[0].Username')
        smb_server_name=$(echo "$ad_config" | jq -r '.[0].SmbServerName')
        organizational_unit=$(echo "$ad_config" | jq -r '.[0].OrganizationalUnit')
        dns_servers=$(echo "$ad_config" | jq -r '.[0].DNS')
        ldap_signing=$(echo "$ad_config" | jq -r '.[0].LdapSigning // false')
        ldap_over_tls=$(echo "$ad_config" | jq -r '.[0].LdapOverTLS // false')
        aes_encryption=$(echo "$ad_config" | jq -r '.[0].AesEncryption // false')
        
        echo ""
        echo "🎯 AD Configuration Summary:"
        echo "   Domain: $domain"
        echo "   Username: $username"
        echo "   SMB Server Name: $smb_server_name"
        echo "   Organizational Unit: $organizational_unit"
        echo "   DNS Servers: $dns_servers"
        echo "   LDAP Signing: $ldap_signing"
        echo "   LDAP over TLS: $ldap_over_tls"
        echo "   AES Encryption: $aes_encryption"
        
        return 0
    else
        echo "❌ No Active Directory configuration found"
        echo "   SMB volumes require Active Directory connection"
        return 1
    fi
}

# Function to test DNS resolution for SMB
test_smb_dns_resolution() {
    echo ""
    echo "🌐 Testing DNS resolution for SMB..."
    
    if [ -z "$dns_servers" ] || [ -z "$domain" ]; then
        echo "❌ DNS configuration not available"
        return 1
    fi
    
    echo "📡 Testing DNS servers for SMB connectivity..."
    
    # Parse DNS servers
    IFS=',' read -ra DNS_ARRAY <<< "$dns_servers"
    
    for dns_server in "${DNS_ARRAY[@]}"; do
        dns_server=$(echo "$dns_server" | tr -d ' ')
        echo ""
        echo "🔍 Testing DNS server: $dns_server"
        
        # Test DNS port 53
        if timeout 5 bash -c "</dev/tcp/$dns_server/53" 2>/dev/null; then
            echo "  ✅ DNS port 53 accessible on $dns_server"
        else
            echo "  ❌ DOCUMENTED ERROR: DNS port 53 not accessible"
            echo "     Error: 'Could not query DNS server'"
            echo "     Solution: Check NSG rules allow DNS traffic"
        fi
        
        # Test domain resolution
        if command -v nslookup >/dev/null 2>&1; then
            echo "  🔍 Testing domain resolution for $domain..."
            if nslookup "$domain" "$dns_server" >/dev/null 2>&1; then
                echo "  ✅ Domain $domain resolves via $dns_server"
            else
                echo "  ❌ DOCUMENTED ERROR: Domain resolution failed"
                echo "     Error: 'Could not query DNS server. Verify network configuration'"
                echo "     Solution: Verify DNS IP is correct and domain exists"
            fi
            
            # Test SMB server name resolution if available
            if [ -n "$smb_server_name" ]; then
                smb_fqdn="${smb_server_name}.${domain}"
                echo "  🔍 Testing SMB server resolution: $smb_fqdn"
                if nslookup "$smb_fqdn" "$dns_server" >/dev/null 2>&1; then
                    echo "  ✅ SMB server name resolves"
                else
                    echo "  ⚠️ SMB server name may not be registered yet"
                fi
            fi
        else
            echo "  ⚠️ nslookup not available - install bind-utils"
        fi
    done
}

# Function to check for documented SMB errors
check_documented_smb_errors() {
    echo ""
    echo "📚 Checking for Documented SMB Error Patterns"
    echo "============================================"
    
    echo ""
    echo "🔍 Common SMB Volume Creation Errors (Microsoft Learn):"
    echo ""
    
    echo "1. DNS Query Error:"
    echo "   Error: 'Could not query DNS server. Verify that the network configuration is correct'"
    echo "   Causes:"
    echo "   • DNS servers not reachable from ANF subnet"
    echo "   • Incorrect DNS IP addresses in AD connection"
    echo "   • NSG blocking DNS traffic (port 53)"
    echo "   • AD DS and volume in different regions (Basic network features)"
    echo "   • Missing VNet peering between AD and volume VNets"
    echo ""
    
    echo "2. Authentication Errors:"
    echo "   Error: 'Unknown user (KRB5KDC_ERR_C_PRINCIPAL_UNKNOWN)'"
    echo "   Solutions:"
    echo "   • Verify username is correct"
    echo "   • Ensure user is part of Administrator group"
    echo "   • For Microsoft Entra Domain Services: user must be in 'Azure AD DC Administrators'"
    echo ""
    
    echo "3. Password Errors:"
    echo "   Error: 'CIFS server account password does not match (KRB5KDC_ERR_PREAUTH_FAILED)'"
    echo "   Solution:"
    echo "   • Verify AD connection password is correct"
    echo "   • Check if password has expired"
    echo ""
    
    echo "4. Organizational Unit Errors:"
    echo "   Error: 'Specified OU does not exist'"
    echo "   Solutions:"
    echo "   • Verify OU path is correct (case-sensitive)"
    echo "   • For Microsoft Entra Domain Services: use 'OU=AADDC Computers'"
    echo "   • Check OU exists in the domain"
    echo ""
    
    echo "5. LDAP Authentication Errors:"
    echo "   Error: 'Unable to SASL bind to LDAP server using GSSAPI'"
    echo "   Solution:"
    echo "   • Create PTR record for AD host machine in reverse lookup zone"
    echo "   • Example: 10.x.x.x -> AD1.contoso.com"
    echo ""
    
    echo "6. Encryption Type Errors:"
    echo "   Error: 'KDC has no support for encryption type (KRB5KDC_ERR_ETYPE_NOSUPP)'"
    echo "   Solution:"
    echo "   • Enable AES Encryption in AD connection"
    echo "   • Enable AES Encryption for service account"
    echo ""
    
    echo "7. LDAP Signing Errors:"
    echo "   Error: 'Strong(er) authentication required'"
    echo "   Solution:"
    echo "   • Enable LDAP Signing in AD connection"
    echo "   • AD requires LDAP signing but connection doesn't have it enabled"
    echo ""
    
    echo "8. LDAP over TLS Errors:"
    echo "   Error: 'This Active Directory has no Server root CA Certificate'"
    echo "   Solution:"
    echo "   • Upload root CA certificate to NetApp account"
    echo "   • Required when LDAP over TLS is enabled for dual-protocol volumes"
    echo ""
    
    echo "9. Machine Account Creation Errors:"
    echo "   Error: 'Initialization of LDAP library failed'"
    echo "   Solution:"
    echo "   • Grant user/service account sufficient privileges"
    echo "   • Account needs permission to create computer objects"
    echo "   • Apply default role with sufficient privileges"
}

# Function to test SMB ports and connectivity
test_smb_connectivity() {
    echo ""
    echo "🔗 Testing SMB connectivity and ports..."
    
    if [ -z "$dns_servers" ]; then
        echo "❌ DNS servers not available for connectivity test"
        return 1
    fi
    
    # Parse DNS servers (these are typically domain controllers)
    IFS=',' read -ra DNS_ARRAY <<< "$dns_servers"
    
    for dc_server in "${DNS_ARRAY[@]}"; do
        dc_server=$(echo "$dc_server" | tr -d ' ')
        echo ""
        echo "🔍 Testing SMB connectivity to DC: $dc_server"
        
        # Test SMB/CIFS port 445
        if timeout 5 bash -c "</dev/tcp/$dc_server/445" 2>/dev/null; then
            echo "  ✅ SMB port 445 accessible"
        else
            echo "  ❌ SMB port 445 NOT accessible"
            echo "     This may cause SMB mount failures"
        fi
        
        # Test LDAP port 389
        if timeout 5 bash -c "</dev/tcp/$dc_server/389" 2>/dev/null; then
            echo "  ✅ LDAP port 389 accessible"
        else
            echo "  ❌ LDAP port 389 NOT accessible"
            echo "     Required for AD authentication"
        fi
        
        # Test LDAPS port 636 (if LDAP over TLS enabled)
        if [ "$ldap_over_tls" = "true" ]; then
            if timeout 5 bash -c "</dev/tcp/$dc_server/636" 2>/dev/null; then
                echo "  ✅ LDAPS port 636 accessible"
            else
                echo "  ❌ LDAPS port 636 NOT accessible"
                echo "     Required for LDAP over TLS"
            fi
        fi
        
        # Test Kerberos port 88
        if timeout 5 bash -c "</dev/tcp/$dc_server/88" 2>/dev/null; then
            echo "  ✅ Kerberos port 88 accessible"
        else
            echo "  ❌ Kerberos port 88 NOT accessible"
            echo "     Required for Kerberos authentication"
        fi
    done
}

# Function to provide dual-protocol specific guidance
dual_protocol_guidance() {
    echo ""
    echo "🔄 Dual-Protocol Volume Specific Guidance"
    echo "========================================"
    echo ""
    echo "📋 Dual-Protocol Requirements:"
    echo "• Active Directory connection configured"
    echo "• Export policy allows both NFS and SMB access"
    echo "• POSIX attributes set on AD DS user objects"
    echo "• LDAP over TLS requires root CA certificate upload"
    echo ""
    echo "🔍 Common Dual-Protocol Errors:"
    echo ""
    echo "1. Permission Denied on Mount:"
    echo "   Error: 'Permission is denied error when mounting'"
    echo "   Cause: UNIX user mapping to Windows user fails"
    echo "   Solution: Ensure POSIX attributes are set on AD DS User objects"
    echo ""
    echo "2. LDAP Configuration Validation:"
    echo "   Error: 'Failed to validate LDAP configuration'"
    echo "   Cause: PTR record missing for AD host machine"
    echo "   Solution: Create reverse lookup zone and PTR record"
    echo "   Example: 10.x.x.x -> AD1.contoso.com"
    echo ""
    echo "3. CA Certificate Missing:"
    echo "   Error: 'This Active Directory has no Server root CA Certificate'"
    echo "   Cause: LDAP over TLS enabled but no root CA certificate"
    echo "   Solution: Upload root CA certificate to NetApp account"
    echo ""
    echo "📁 Example Dual-Protocol Export Policy:"
    echo "{"
    echo "  \"rules\": ["
    echo "    {"
    echo "      \"ruleIndex\": 1,"
    echo "      \"unixReadOnly\": false,"
    echo "      \"unixReadWrite\": true,"
    echo "      \"cifs\": true,"
    echo "      \"nfsv3\": true,"
    echo "      \"nfsv41\": true,"
    echo "      \"allowedClients\": \"0.0.0.0/0\","
    echo "      \"hasRootAccess\": true"
    echo "    }"
    echo "  ]"
    echo "}"
}

# Function to provide troubleshooting commands
provide_troubleshooting_commands() {
    echo ""
    echo "🔧 Troubleshooting Commands"
    echo "========================="
    echo ""
    echo "1. Check AD Connection Status:"
    echo "az netappfiles account ad list \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount"
    echo ""
    echo "2. Update AD Connection (fix common issues):"
    echo "az netappfiles account ad update \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --active-directory-id \"\$AD_CONNECTION_ID\" \\"
    echo "  --aes-encryption true \\"
    echo "  --ldap-signing true \\"
    echo "  --ldap-over-tls true"
    echo ""
    echo "3. Check Volume Creation Logs:"
    echo "az monitor activity-log list \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --offset 1h \\"
    echo "  --query \"[?contains(operationName.value, 'Microsoft.NetApp/netAppAccounts/capacityPools/volumes')]\""
    echo ""
    echo "4. Test DNS Resolution:"
    echo "nslookup $domain"
    echo "nslookup \$DNS_SERVER_IP"
    echo ""
    echo "5. Check Network Security Groups:"
    echo "az network nsg rule list \\"
    echo "  --resource-group \$NSG_RESOURCE_GROUP \\"
    echo "  --nsg-name \$NSG_NAME \\"
    echo "  --query \"[?direction=='Inbound' && (destinationPortRange=='53' || destinationPortRange=='389' || destinationPortRange=='445' || destinationPortRange=='88')]\""
}

# Main execution
detect_subscription

echo "Starting comprehensive SMB and Dual-Protocol troubleshooting..."
echo "Based on Microsoft Learn troubleshooting documentation"
echo ""

if check_smb_volume_config; then
    if check_ad_configuration; then
        test_smb_dns_resolution
        test_smb_connectivity
        
        if [ "$is_dual_protocol" = true ]; then
            dual_protocol_guidance
        fi
    fi
    
    check_documented_smb_errors
    provide_troubleshooting_commands
else
    echo ""
    echo "❌ Volume configuration issues detected"
    echo ""
    echo "🔧 To create SMB volume:"
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
    echo "  --creation-token \"smb-volume\" \\"
    echo "  --protocol-types CIFS"
    echo ""
    echo "🔧 To create dual-protocol volume:"
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
    echo "  --creation-token \"dual-protocol-volume\" \\"
    echo "  --protocol-types \"CIFS,NFSv3\""
fi

echo ""
echo "🏁 SMB and Dual-Protocol troubleshooting complete!"
echo "📖 Reference: https://learn.microsoft.com/azure/azure-netapp-files/troubleshoot-volumes"
