#!/bin/bash
# Azure NetApp Files LDAP and Kerberos Authentication Troubleshooting Script
# Diagnoses authentication issues with Active Directory, LDAP, and Kerberos
#
# Last tested: 2025-01-24
# Test method: Validated on Azure Cloud Shell and Windows Subsystem for Linux
# Azure CLI version required: 2.30.0 or later
# Required extensions: None (uses core Azure CLI commands)
# 
# This script provides comprehensive troubleshooting for:
# - Active Directory connection validation
# - DNS resolution testing
# - LDAP connectivity testing (ports 389, 636, 3268, 3269)
# - Kerberos connectivity testing (ports 88, 464)
# - Volume authentication configuration analysis
# - SMB and dual-protocol authentication checks

# Variables (customize these - using random suffixes for unique resource names)
randomSuffix=$(shuf -i 1000-9999 -n 1 2>/dev/null || echo $RANDOM)
resourceGroup="${ANF_RESOURCE_GROUP:-anf-rg-${randomSuffix}}"
netAppAccount="${ANF_ACCOUNT:-anf-account-${randomSuffix}}"
volumeName="${ANF_VOLUME:-volume-${randomSuffix}}"
capacityPool="${ANF_POOL:-pool-${randomSuffix}}"
adConnectionName="${ANF_AD_CONNECTION:-ad-connection-${randomSuffix}}"
subscriptionId=""  # Will be detected automatically if empty

echo "🔐 Azure NetApp Files LDAP & Kerberos Authentication Troubleshooting"
echo "=================================================================="

# Function to detect subscription ID
detect_subscription() {
    if [ -z "$subscriptionId" ]; then
        echo "🔍 Detecting subscription ID..."
        subscriptionId=$(az account show --query id -o tsv 2>/dev/null)
        echo "📍 Using subscription: $subscriptionId"
    fi
}

# Function to check Active Directory connection
check_ad_connection() {
    echo ""
    echo "🏢 Checking Active Directory connection..."
    
    ad_connections=$(az netappfiles account ad list \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --query "[].{ConnectionName:activeDirectoryId,Domain:domain,DNS:dns,Username:username,SmbServerName:smbServerName,OrganizationalUnit:organizationalUnit,AesEncryption:aesEncryption,LdapSigning:ldapSigning,LdapOverTLS:ldapOverTLS,AllowLocalNfsUsersWithLdap:allowLocalNfsUsersWithLdap}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$ad_connections" != "[]" ]; then
        echo "✅ Active Directory connections found:"
        echo "$ad_connections" | jq .
        
        # Extract key information
        domain=$(echo "$ad_connections" | jq -r '.[0].Domain')
        dns_servers=$(echo "$ad_connections" | jq -r '.[0].DNS')
        smb_server=$(echo "$ad_connections" | jq -r '.[0].SmbServerName')
        ldap_signing=$(echo "$ad_connections" | jq -r '.[0].LdapSigning // false')
        ldap_over_tls=$(echo "$ad_connections" | jq -r '.[0].LdapOverTLS // false')
        aes_encryption=$(echo "$ad_connections" | jq -r '.[0].AesEncryption // false')
        
        echo ""
        echo "🎯 AD Configuration Summary:"
        echo "   Domain: $domain"
        echo "   DNS Servers: $dns_servers"
        echo "   SMB Server Name: $smb_server"
        echo "   LDAP Signing: $ldap_signing"
        echo "   LDAP over TLS: $ldap_over_tls"
        echo "   AES Encryption: $aes_encryption"
        
        return 0
    else
        echo "❌ No Active Directory connections found"
        return 1
    fi
}

# Function to test DNS resolution
test_dns_resolution() {
    echo ""
    echo "🌐 Testing DNS resolution..."
    
    if [ -z "$domain" ] || [ -z "$dns_servers" ]; then
        echo "❌ Domain or DNS servers not available"
        return 1
    fi
    
    # Parse DNS servers (comma-separated)
    IFS=',' read -ra DNS_ARRAY <<< "$dns_servers"
    
    echo "🔍 Testing DNS servers..."
    for dns_server in "${DNS_ARRAY[@]}"; do
        dns_server=$(echo "$dns_server" | tr -d ' ')
        echo "📡 Testing DNS server: $dns_server"
        
        # Test if DNS server is reachable
        if timeout 5 bash -c "</dev/tcp/$dns_server/53" 2>/dev/null; then
            echo "  ✅ Port 53 accessible on $dns_server"
        else
            echo "  ❌ Port 53 NOT accessible on $dns_server"
        fi
        
        # Test domain resolution using nslookup if available
        if command -v nslookup >/dev/null 2>&1; then
            echo "  🔍 Testing domain resolution for $domain..."
            if nslookup "$domain" "$dns_server" >/dev/null 2>&1; then
                echo "  ✅ Domain $domain resolves via $dns_server"
            else
                echo "  ❌ Domain $domain does NOT resolve via $dns_server"
            fi
            
            # Test reverse DNS
            echo "  🔍 Testing reverse DNS for $dns_server..."
            if nslookup "$dns_server" >/dev/null 2>&1; then
                echo "  ✅ Reverse DNS works for $dns_server"
            else
                echo "  ⚠️ Reverse DNS may not work for $dns_server"
            fi
        else
            echo "  ⚠️ nslookup not available - install bind-utils package"
        fi
    done
}

# Function to test LDAP connectivity
test_ldap_connectivity() {
    echo ""
    echo "📚 Testing LDAP connectivity..."
    
    if [ -z "$domain" ] || [ -z "$dns_servers" ]; then
        echo "❌ Domain or DNS servers not available"
        return 1
    fi
    
    # Parse DNS servers
    IFS=',' read -ra DNS_ARRAY <<< "$dns_servers"
    
    for dns_server in "${DNS_ARRAY[@]}"; do
        dns_server=$(echo "$dns_server" | tr -d ' ')
        echo "🔍 Testing LDAP on $dns_server..."
        
        # Test LDAP port 389 (standard LDAP)
        if timeout 5 bash -c "</dev/tcp/$dns_server/389" 2>/dev/null; then
            echo "  ✅ LDAP port 389 accessible on $dns_server"
        else
            echo "  ❌ LDAP port 389 NOT accessible on $dns_server"
        fi
        
        # Test LDAPS port 636 (LDAP over SSL/TLS)
        if timeout 5 bash -c "</dev/tcp/$dns_server/636" 2>/dev/null; then
            echo "  ✅ LDAPS port 636 accessible on $dns_server"
        else
            echo "  ❌ LDAPS port 636 NOT accessible on $dns_server"
        fi
        
        # Test Global Catalog LDAP port 3268
        if timeout 5 bash -c "</dev/tcp/$dns_server/3268" 2>/dev/null; then
            echo "  ✅ Global Catalog LDAP port 3268 accessible on $dns_server"
        else
            echo "  ❌ Global Catalog LDAP port 3268 NOT accessible on $dns_server"
        fi
        
        # Test Global Catalog LDAPS port 3269
        if timeout 5 bash -c "</dev/tcp/$dns_server/3269" 2>/dev/null; then
            echo "  ✅ Global Catalog LDAPS port 3269 accessible on $dns_server"
        else
            echo "  ❌ Global Catalog LDAPS port 3269 NOT accessible on $dns_server"
        fi
    done
    
    # LDAP configuration recommendations
    echo ""
    echo "💡 LDAP Configuration Recommendations:"
    if [ "$ldap_signing" = "true" ]; then
        echo "  ✅ LDAP signing is enabled (recommended for security)"
    else
        echo "  ⚠️ LDAP signing is disabled (consider enabling for security)"
    fi
    
    if [ "$ldap_over_tls" = "true" ]; then
        echo "  ✅ LDAP over TLS is enabled (recommended for security)"
    else
        echo "  ⚠️ LDAP over TLS is disabled (consider enabling for security)"
    fi
}

# Function to test Kerberos connectivity
test_kerberos_connectivity() {
    echo ""
    echo "🎫 Testing Kerberos connectivity..."
    
    if [ -z "$domain" ] || [ -z "$dns_servers" ]; then
        echo "❌ Domain or DNS servers not available"
        return 1
    fi
    
    # Parse DNS servers
    IFS=',' read -ra DNS_ARRAY <<< "$dns_servers"
    
    for dns_server in "${DNS_ARRAY[@]}"; do
        dns_server=$(echo "$dns_server" | tr -d ' ')
        echo "🔍 Testing Kerberos on $dns_server..."
        
        # Test Kerberos port 88 (both TCP and UDP)
        if timeout 5 bash -c "</dev/tcp/$dns_server/88" 2>/dev/null; then
            echo "  ✅ Kerberos TCP port 88 accessible on $dns_server"
        else
            echo "  ❌ Kerberos TCP port 88 NOT accessible on $dns_server"
        fi
        
        # Test Kerberos Password Change port 464
        if timeout 5 bash -c "</dev/tcp/$dns_server/464" 2>/dev/null; then
            echo "  ✅ Kerberos Password Change port 464 accessible on $dns_server"
        else
            echo "  ❌ Kerberos Password Change port 464 NOT accessible on $dns_server"
        fi
    done
    
    # AES encryption recommendation
    echo ""
    echo "💡 Kerberos Configuration Recommendations:"
    if [ "$aes_encryption" = "true" ]; then
        echo "  ✅ AES encryption is enabled (recommended for security)"
    else
        echo "  ⚠️ AES encryption is disabled (consider enabling for security)"
    fi
}

# Function to check volume-specific authentication settings
check_volume_authentication() {
    echo ""
    echo "💾 Checking volume authentication settings..."
    
    volume_auth_info=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "{Name:name,ProtocolTypes:protocolTypes,KerberosEnabled:kerberosEnabled,SmbEncryption:smbEncryption,SmbAccessBasedEnumeration:smbAccessBasedEnumeration,SmbNonBrowsable:smbNonBrowsable,UnixPermissions:unixPermissions,HasRootAccess:hasRootAccess}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Volume authentication configuration:"
        echo "$volume_auth_info" | jq .
        
        # Extract authentication details
        protocol_types=$(echo "$volume_auth_info" | jq -r '.ProtocolTypes[]' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        kerberos_enabled=$(echo "$volume_auth_info" | jq -r '.KerberosEnabled // false')
        smb_encryption=$(echo "$volume_auth_info" | jq -r '.SmbEncryption // false')
        unix_permissions=$(echo "$volume_auth_info" | jq -r '.UnixPermissions // "0755"')
        
        echo ""
        echo "🎯 Authentication Summary:"
        echo "   Protocol Types: $protocol_types"
        echo "   Kerberos Enabled: $kerberos_enabled"
        echo "   SMB Encryption: $smb_encryption"
        echo "   Unix Permissions: $unix_permissions"
        
        # Check for dual protocol volumes
        if echo "$protocol_types" | grep -q "NFSv3\|NFSv4.1" && echo "$protocol_types" | grep -q "CIFS"; then
            echo "  ℹ️ This is a dual protocol volume (NFS + SMB)"
            echo "     Requires careful authentication configuration"
        fi
        
        return 0
    else
        echo "❌ Could not retrieve volume authentication information"
        return 1
    fi
}

# Function to check SMB authentication issues
check_smb_authentication() {
    echo ""
    echo "📁 Checking SMB authentication configuration..."
    
    # Get export policy (includes SMB settings for dual protocol)
    export_policy=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "exportPolicy.rules" -o json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$export_policy" != "null" ]; then
        echo "📋 Current export policy (affects SMB access):"
        echo "$export_policy" | jq .
        
        # Check for Kerberos settings in export policy
        kerberos_5_readonly=$(echo "$export_policy" | jq -r '.[].kerberos5ReadOnly // false')
        kerberos_5_readwrite=$(echo "$export_policy" | jq -r '.[].kerberos5ReadWrite // false')
        kerberos_5i_readonly=$(echo "$export_policy" | jq -r '.[].kerberos5iReadOnly // false')
        kerberos_5i_readwrite=$(echo "$export_policy" | jq -r '.[].kerberos5iReadWrite // false')
        kerberos_5p_readonly=$(echo "$export_policy" | jq -r '.[].kerberos5pReadOnly // false')
        kerberos_5p_readwrite=$(echo "$export_policy" | jq -r '.[].kerberos5pReadWrite // false')
        
        echo ""
        echo "🎫 Kerberos Export Policy Settings:"
        echo "   Kerberos 5 RO: $kerberos_5_readonly"
        echo "   Kerberos 5 RW: $kerberos_5_readwrite"
        echo "   Kerberos 5i RO: $kerberos_5i_readonly"
        echo "   Kerberos 5i RW: $kerberos_5i_readwrite"
        echo "   Kerberos 5p RO: $kerberos_5p_readonly"
        echo "   Kerberos 5p RW: $kerberos_5p_readwrite"
    fi
}

# Function to provide authentication troubleshooting recommendations
authentication_troubleshooting_recommendations() {
    echo ""
    echo "💡 Authentication Troubleshooting Recommendations"
    echo "================================================"
    echo ""
    echo "🔧 Common Authentication Issues and Solutions:"
    echo ""
    echo "1. 🏢 Active Directory Connection Issues:"
    echo "   • Verify AD credentials are correct and not expired"
    echo "   • Ensure user has privileges to create computer accounts"
    echo "   • Check if DNS servers are reachable and resolving properly"
    echo "   • Verify organizational unit (OU) path is correct"
    echo ""
    echo "2. 📚 LDAP Issues:"
    echo "   • Ensure LDAP ports (389, 636, 3268, 3269) are accessible"
    echo "   • Enable LDAP signing for security"
    echo "   • Configure LDAP over TLS for encrypted communication"
    echo "   • Check if LDAP search base is correctly configured"
    echo ""
    echo "3. 🎫 Kerberos Issues:"
    echo "   • Verify Kerberos ports (88, 464) are accessible"
    echo "   • Enable AES encryption for enhanced security"
    echo "   • Check time synchronization between client and DC"
    echo "   • Verify SPN (Service Principal Name) registration"
    echo ""
    echo "4. 🌐 Network and Firewall Issues:"
    echo "   • Check NSG rules allow AD/LDAP/Kerberos traffic"
    echo "   • Verify UDR configuration doesn't block AD connectivity"
    echo "   • Ensure subnet delegation is properly configured"
    echo "   • Test connectivity from ANF subnet to AD servers"
    echo ""
    echo "5. 📁 SMB/CIFS Authentication:"
    echo "   • Verify SMB encryption settings match requirements"
    echo "   • Check export policy Kerberos settings"
    echo "   • Ensure computer account is created in correct OU"
    echo "   • Verify SMB protocol version compatibility"
    echo ""
    echo "Example Azure CLI commands for troubleshooting:"
    echo ""
    echo "# Check AD connection status"
    echo "az netappfiles account ad list \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount"
    echo ""
    echo "# Update AD connection with LDAP settings"
    echo "az netappfiles account ad update \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --active-directory-id \"\$AD_CONNECTION_ID\" \\"
    echo "  --ldap-signing true \\"
    echo "  --ldap-over-tls true \\"
    echo "  --aes-encryption true"
    echo ""
    echo "# Check volume authentication settings"
    echo "az netappfiles volume show \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --name $volumeName \\"
    echo "  --query \"{Protocols:protocolTypes,Kerberos:kerberosEnabled,SMBEncryption:smbEncryption}\""
}

# Function to test common authentication scenarios
test_authentication_scenarios() {
    echo ""
    echo "🧪 Testing Common Authentication Scenarios"
    echo "========================================="
    echo ""
    echo "The following tests require manual verification:"
    echo ""
    echo "1. 🔐 User Authentication Test:"
    echo "   On a domain-joined client, test:"
    echo "   smbclient //\$smb_server.\$domain/\$volumeName -k"
    echo ""
    echo "2. 📚 LDAP User Lookup Test:"
    echo "   ldapsearch -H ldap://\$dns_server -D 'user@\$domain' -W -b 'DC=\$(echo \$domain | sed 's/\./,DC=/g')' '(sAMAccountName=username)'"
    echo ""
    echo "3. 🎫 Kerberos Ticket Test:"
    echo "   kinit user@\$(echo \$domain | tr '[:lower:]' '[:upper:]')"
    echo "   klist"
    echo ""
    echo "4. 📁 SMB Mount Test:"
    echo "   mount -t cifs //\$smb_server.\$domain/\$volumeName /mnt/anf -o username=user@\$domain,sec=krb5"
    echo ""
    echo "5. 🔄 NFS with Kerberos Test:"
    echo "   mount -t nfs -o sec=krb5,vers=4.1 \$mount_ip:/\$creation_token /mnt/anf"
}

# Main execution
detect_subscription

echo "Starting comprehensive LDAP and Kerberos authentication troubleshooting..."

if check_ad_connection; then
    test_dns_resolution
    test_ldap_connectivity
    test_kerberos_connectivity
    
    if check_volume_authentication; then
        check_smb_authentication
    fi
    
    authentication_troubleshooting_recommendations
    test_authentication_scenarios
else
    echo ""
    echo "❌ No Active Directory connection found. To set up AD authentication:"
    echo ""
    echo "1. Create AD connection:"
    echo "az netappfiles account ad add \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --domain \"your-domain.com\" \\"
    echo "  --dns \"10.0.0.4,10.0.0.5\" \\"
    echo "  --username \"admin-user\" \\"
    echo "  --password \"your-password\" \\"
    echo "  --smb-server-name \"anf-smb-server\" \\"
    echo "  --organizational-unit \"OU=ANF,DC=your-domain,DC=com\" \\"
    echo "  --aes-encryption true \\"
    echo "  --ldap-signing true \\"
    echo "  --ldap-over-tls true"
    echo ""
    echo "2. Enable authentication on volume:"
    echo "az netappfiles volume update \\"
    echo "  --resource-group $resourceGroup \\"
    echo "  --account-name $netAppAccount \\"
    echo "  --pool-name $capacityPool \\"
    echo "  --name $volumeName \\"
    echo "  --kerberos-enabled true \\"
    echo "  --smb-encryption true"
fi

echo ""
echo "🏁 LDAP and Kerberos authentication troubleshooting complete!"
echo "For additional help, consult Azure NetApp Files authentication documentation."
