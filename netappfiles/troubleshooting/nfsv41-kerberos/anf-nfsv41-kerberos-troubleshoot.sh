#!/bin/bash
# Azure NetApp Files NFSv4.1 Kerberos Troubleshooting Script
# Based on Microsoft Learn troubleshooting documentation
# Diagnoses NFSv4.1 Kerberos authentication and mounting issues

# Variables (customize these)
resourceGroup="your-anf-rg"
netAppAccount="your-anf-account"
capacityPool="your-pool"
volumeName="your-volume"
clientHostname=""  # Will be detected if empty
subscriptionId=""  # Will be detected automatically if empty

echo "🎫 Azure NetApp Files NFSv4.1 Kerberos Troubleshooting"
echo "====================================================="

# Function to detect subscription ID and client hostname
detect_environment() {
    if [ -z "$subscriptionId" ]; then
        echo "🔍 Detecting subscription ID..."
        subscriptionId=$(az account show --query id -o tsv 2>/dev/null)
        echo "📍 Using subscription: $subscriptionId"
    fi
    
    if [ -z "$clientHostname" ]; then
        echo "🔍 Detecting client hostname..."
        clientHostname=$(hostname)
        echo "📍 Client hostname: $clientHostname"
        
        # Check hostname length (documented requirement)
        hostname_length=${#clientHostname}
        if [ $hostname_length -gt 15 ]; then
            echo "⚠️ Hostname is $hostname_length characters (>15). This may cause issues."
            echo "   Microsoft Learn recommendation: Reduce hostname to <15 characters"
        fi
    fi
}

# Function to check NFSv4.1 Kerberos volume configuration
check_nfsv41_kerberos_config() {
    echo ""
    echo "🔧 Checking NFSv4.1 Kerberos volume configuration..."
    
    volume_info=$(az netappfiles volume show \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --pool-name $capacityPool \
        --name $volumeName \
        --query "{Name:name,ProtocolTypes:protocolTypes,KerberosEnabled:kerberosEnabled,ExportPolicy:exportPolicy,State:provisioningState}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Volume configuration found:"
        echo "$volume_info" | jq .
        
        # Extract key information
        protocol_types=$(echo "$volume_info" | jq -r '.ProtocolTypes[]' 2>/dev/null)
        kerberos_enabled=$(echo "$volume_info" | jq -r '.KerberosEnabled // false')
        export_policy=$(echo "$volume_info" | jq -r '.ExportPolicy.rules')
        volume_state=$(echo "$volume_info" | jq -r '.State')
        
        echo ""
        echo "🎯 Configuration Analysis:"
        echo "   Protocol Types: $protocol_types"
        echo "   Kerberos Enabled: $kerberos_enabled"
        echo "   Volume State: $volume_state"
        
        # Check for documented error conditions
        if echo "$protocol_types" | grep -q "NFSv3"; then
            echo "❌ DOCUMENTED ERROR: NFSv3 detected with Kerberos"
            echo "   Error: 'Export policy rules does not match kerberosEnabled flag'"
            echo "   Solution: Azure NetApp Files doesn't support Kerberos for NFSv3"
            echo "   Action: Use NFSv4.1 only for Kerberos volumes"
            return 1
        fi
        
        if [ "$kerberos_enabled" = "true" ] && echo "$protocol_types" | grep -q "NFSv4.1"; then
            echo "✅ NFSv4.1 with Kerberos properly configured"
        else
            echo "❌ Configuration mismatch detected"
            echo "   Kerberos requires NFSv4.1 protocol"
        fi
        
        # Analyze export policy for Kerberos settings
        if [ "$export_policy" != "null" ]; then
            echo ""
            echo "🔐 Export Policy Kerberos Analysis:"
            kerberos_rules=$(echo "$export_policy" | jq '[.[] | select(.kerberos5ReadOnly == true or .kerberos5ReadWrite == true or .kerberos5iReadOnly == true or .kerberos5iReadWrite == true or .kerberos5pReadOnly == true or .kerberos5pReadWrite == true)]')
            
            if [ "$kerberos_rules" != "[]" ]; then
                echo "✅ Kerberos rules found in export policy:"
                echo "$kerberos_rules" | jq .
            else
                echo "❌ No Kerberos rules found in export policy"
                echo "   This may cause access denied errors"
            fi
        fi
        
        return 0
    else
        echo "❌ Could not retrieve volume information"
        return 1
    fi
}

# Function to check Active Directory Kerberos configuration
check_ad_kerberos_config() {
    echo ""
    echo "🏢 Checking Active Directory Kerberos configuration..."
    
    ad_config=$(az netappfiles account ad list \
        --resource-group $resourceGroup \
        --account-name $netAppAccount \
        --query "[].{Domain:domain,KdcIP:kdcIP,AdServerName:serverName,AesEncryption:aesEncryption,SmbServerName:smbServerName}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$ad_config" != "[]" ]; then
        echo "✅ Active Directory configuration found:"
        echo "$ad_config" | jq .
        
        # Extract key information
        domain=$(echo "$ad_config" | jq -r '.[0].Domain')
        kdc_ip=$(echo "$ad_config" | jq -r '.[0].KdcIP')
        ad_server_name=$(echo "$ad_config" | jq -r '.[0].AdServerName')
        aes_encryption=$(echo "$ad_config" | jq -r '.[0].AesEncryption // false')
        smb_server_name=$(echo "$ad_config" | jq -r '.[0].SmbServerName')
        
        echo ""
        echo "🎯 Kerberos Configuration Summary:"
        echo "   Domain: $domain"
        echo "   KDC IP: $kdc_ip"
        echo "   AD Server Name: $ad_server_name"
        echo "   SMB Server Name: $smb_server_name"
        echo "   AES Encryption: $aes_encryption"
        
        # Check for documented error: KDC IP issues
        if [ "$kdc_ip" = "null" ] || [ -z "$kdc_ip" ]; then
            echo "❌ DOCUMENTED ERROR: KDC IP not configured"
            echo "   Error: 'This NetApp account has no configured Active Directory connections'"
            echo "   Solution: Configure KDC IP and AD Server Name in Active Directory connection"
        else
            echo "✅ KDC IP is configured"
        fi
        
        # Check AES encryption
        if [ "$aes_encryption" = "false" ]; then
            echo "⚠️ AES encryption is disabled"
            echo "   Microsoft Learn recommendation: Enable AES-256 encryption"
            echo "   This may cause: 'KDC has no support for encryption type' error"
        else
            echo "✅ AES encryption is enabled"
        fi
        
        return 0
    else
        echo "❌ DOCUMENTED ERROR: No Active Directory connections found"
        echo "   Error: 'This NetApp account has no configured Active Directory connections'"
        echo "   Solution: Configure Active Directory for the NetApp account"
        return 1
    fi
}

# Function to test DNS and reverse DNS resolution
test_dns_resolution() {
    echo ""
    echo "🌐 Testing DNS and Reverse DNS Resolution..."
    
    if [ -z "$domain" ] || [ -z "$kdc_ip" ] || [ -z "$smb_server_name" ]; then
        echo "❌ Missing DNS configuration information"
        return 1
    fi
    
    # Test forward DNS resolution
    echo "🔍 Testing forward DNS resolution..."
    smb_fqdn="${smb_server_name}.${domain}"
    echo "Testing: $smb_fqdn"
    
    if command -v nslookup >/dev/null 2>&1; then
        echo "📡 Forward DNS lookup for $smb_fqdn:"
        forward_result=$(nslookup "$smb_fqdn" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "✅ Forward DNS resolution successful"
            resolved_ip=$(echo "$forward_result" | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
            echo "   Resolved IP: $resolved_ip"
            
            # Test reverse DNS resolution
            echo ""
            echo "🔄 Testing reverse DNS resolution for $resolved_ip..."
            reverse_result=$(nslookup "$resolved_ip" 2>/dev/null)
            if [ $? -eq 0 ]; then
                reverse_name=$(echo "$reverse_result" | grep "name =" | awk '{print $4}' | sed 's/\.$//')
                echo "   Reverse resolves to: $reverse_name"
                
                if [ "$reverse_name" = "$smb_fqdn" ]; then
                    echo "✅ Reverse DNS resolution matches forward resolution"
                else
                    echo "❌ DOCUMENTED ERROR: Reverse DNS mismatch"
                    echo "   Forward: $smb_fqdn -> $resolved_ip"
                    echo "   Reverse: $resolved_ip -> $reverse_name"
                    echo "   Error: 'Hostname lookup failed'"
                    echo "   Solution: Create PTR record in reverse lookup zone"
                    echo "   Required PTR: $resolved_ip -> $smb_fqdn"
                fi
            else
                echo "❌ DOCUMENTED ERROR: Reverse DNS lookup failed"
                echo "   Error: 'Hostname lookup failed'"
                echo "   Solution: Create reverse lookup zone and PTR record"
                echo "   Required PTR: $resolved_ip -> $smb_fqdn"
            fi
        else
            echo "❌ DOCUMENTED ERROR: Forward DNS resolution failed"
            echo "   Error: 'Could not query DNS server'"
            echo "   Solution: Verify DNS configuration and network connectivity"
        fi
    else
        echo "⚠️ nslookup not available - install bind-utils package"
        echo "   Cannot verify DNS resolution (critical for NFSv4.1 Kerberos)"
    fi
}

# Function to test Kerberos connectivity and time sync
test_kerberos_connectivity() {
    echo ""
    echo "🎫 Testing Kerberos connectivity and configuration..."
    
    if [ -z "$kdc_ip" ]; then
        echo "❌ KDC IP not available"
        return 1
    fi
    
    # Test KDC connectivity
    echo "🔍 Testing KDC connectivity on $kdc_ip..."
    if timeout 5 bash -c "</dev/tcp/$kdc_ip/88" 2>/dev/null; then
        echo "✅ KDC port 88 is accessible"
    else
        echo "❌ DOCUMENTED ERROR: KDC port 88 not accessible"
        echo "   Error: Connection timeout to KDC"
        echo "   Solution: Check firewall rules and NSG configuration"
    fi
    
    # Check time synchronization
    echo ""
    echo "🕒 Checking time synchronization..."
    echo "Current system time: $(date)"
    echo "⚠️ CRITICAL: Time must be synchronized within 5-minute skew"
    echo "   NFS client, AD, and Azure NetApp Files must be time-synchronized"
    echo "   Time skew can cause: 'access denied by server' errors"
    
    # Check if chrony or ntp is running
    if systemctl is-active --quiet chronyd 2>/dev/null; then
        echo "✅ chronyd service is running"
        chrony_status=$(chronyc tracking 2>/dev/null | grep "System time" || echo "Unable to get chrony status")
        echo "   $chrony_status"
    elif systemctl is-active --quiet ntp 2>/dev/null; then
        echo "✅ NTP service is running"
    else
        echo "⚠️ No time synchronization service detected"
        echo "   Install and configure chrony or ntp"
    fi
}

# Function to check NFS machine account and AES encryption
check_nfs_machine_account() {
    echo ""
    echo "🖥️ NFS Machine Account Configuration Check..."
    
    if [ -z "$smb_server_name" ]; then
        echo "❌ SMB server name not available"
        return 1
    fi
    
    # Extract NetBIOS name from SMB server name
    netbios_name=$(echo "$smb_server_name" | cut -d'-' -f1-3)  # Adjust based on naming convention
    
    echo "📋 Expected NFS machine account pattern:"
    echo "   Format: NFS-<SMB_NETBIOS_NAME>-<random_chars>"
    echo "   Example: NFS-$netbios_name-64"
    echo ""
    echo "💡 Required PowerShell commands on AD server:"
    echo "   Set-ADComputer <NFS_MACHINE_ACCOUNT> -KerberosEncryptionType AES256"
    echo "   Example: Set-ADComputer NFS-$netbios_name-64 -KerberosEncryptionType AES256"
    echo ""
    echo "🔍 Verification commands:"
    echo "   Get-ADComputer <NFS_MACHINE_ACCOUNT> -Properties KerberosEncryptionType"
    echo "   Ensure AES256 is set to prevent 'KDC has no support for encryption type'"
}

# Function to provide mount troubleshooting
mount_troubleshooting() {
    echo ""
    echo "🗂️ NFSv4.1 Kerberos Mount Troubleshooting"
    echo "========================================"
    
    if [ -z "$smb_server_name" ] || [ -z "$domain" ]; then
        echo "❌ Missing mount target information"
        return 1
    fi
    
    mount_target="${smb_server_name}.${domain}"
    
    echo "🎯 Mount Target: $mount_target"
    echo ""
    echo "📋 Pre-mount Checklist:"
    echo "1. ✅ Ensure NFS client services are running:"
    echo "   systemctl enable nfs-client.target"
    echo "   systemctl start nfs-client.target"
    echo "   systemctl restart rpc-gssd.service"
    echo ""
    echo "2. ✅ Obtain Kerberos ticket:"
    echo "   kinit <administrator>"
    echo "   klist  # Verify ticket"
    echo ""
    echo "3. ✅ Check hostname length (<15 characters):"
    echo "   Current hostname: $clientHostname ($hostname_length chars)"
    if [ $hostname_length -gt 15 ]; then
        echo "   ⚠️ Hostname too long - may cause mount failures"
    fi
    echo ""
    echo "🔧 Common Mount Errors and Solutions:"
    echo ""
    echo "Error: 'access denied by server when mounting volume'"
    echo "Solutions:"
    echo "• Verify A/PTR records for $mount_target"
    echo "• Check reverse DNS: nslookup <mount_ip> should resolve to $mount_target only"
    echo "• Set AES-256 on NFS machine account in AD"
    echo "• Verify time synchronization (within 5-minute skew)"
    echo "• Get Kerberos ticket: kinit <administrator>"
    echo "• Restart NFS client and rpc-gssd service"
    echo ""
    echo "Error: 'an incorrect mount option was specified'"
    echo "Solution:"
    echo "• Reboot the NFS client"
    echo "• Check NFS client configuration"
    echo ""
    echo "Error: 'Hostname lookup failed'"
    echo "Solution:"
    echo "• Create reverse lookup zone on DNS server"
    echo "• Add PTR record: <IP> -> $mount_target"
    echo ""
    echo "📁 Example Mount Commands:"
    echo "# Basic NFSv4.1 Kerberos mount"
    echo "mount -t nfs -o sec=krb5,vers=4.1 $mount_target:/<creation_token> /mnt/anf"
    echo ""
    echo "# With additional options"
    echo "mount -t nfs -o sec=krb5,vers=4.1,hard,intr $mount_target:/<creation_token> /mnt/anf"
    echo ""
    echo "# Alternative security levels"
    echo "mount -t nfs -o sec=krb5i,vers=4.1 $mount_target:/<creation_token> /mnt/anf  # Integrity"
    echo "mount -t nfs -o sec=krb5p,vers=4.1 $mount_target:/<creation_token> /mnt/anf  # Privacy"
}

# Function to check documented error patterns
check_documented_errors() {
    echo ""
    echo "📚 Microsoft Learn Documented Error Patterns"
    echo "==========================================="
    echo ""
    echo "🔍 Common NFSv4.1 Kerberos Errors from Documentation:"
    echo ""
    echo "1. 'Export policy rules does not match kerberosEnabled flag'"
    echo "   Cause: Kerberos enabled but NFSv3 in protocol types"
    echo "   Solution: Use NFSv4.1 only for Kerberos volumes"
    echo ""
    echo "2. 'This NetApp account has no configured Active Directory connections'"
    echo "   Cause: Missing KDC IP and AD Server Name configuration"
    echo "   Solution: Configure Active Directory with KDC IP and server name"
    echo ""
    echo "3. 'access denied by server when mounting volume'"
    echo "   Causes: DNS issues, time skew, missing AES encryption, wrong Kerberos ticket"
    echo "   Solutions: Fix DNS/reverse DNS, sync time, set AES-256, get valid ticket"
    echo ""
    echo "4. 'KDC has no support for encryption type'"
    echo "   Cause: AES encryption not enabled on AD connection or machine account"
    echo "   Solution: Enable AES encryption in AD connection and set AES-256 on NFS machine account"
    echo ""
    echo "5. 'Failed to enable NFS Kerberos on LIF'"
    echo "   Cause: Wrong KDC IP address"
    echo "   Solution: Update KDC IP and recreate volume"
    echo ""
    echo "6. 'Hostname lookup failed'"
    echo "   Cause: Missing or incorrect PTR records"
    echo "   Solution: Create reverse lookup zone and proper PTR records"
    echo ""
    echo "7. 'an incorrect mount option was specified'"
    echo "   Cause: NFS client configuration issue"
    echo "   Solution: Reboot NFS client"
}

# Main execution
detect_environment

echo "Starting comprehensive NFSv4.1 Kerberos troubleshooting..."
echo "Based on Microsoft Learn troubleshooting documentation"
echo ""

if check_nfsv41_kerberos_config; then
    if check_ad_kerberos_config; then
        test_dns_resolution
        test_kerberos_connectivity
        check_nfs_machine_account
        mount_troubleshooting
    fi
    check_documented_errors
else
    echo ""
    echo "❌ Volume configuration issues detected"
    echo ""
    echo "🔧 To create NFSv4.1 Kerberos volume:"
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
    echo "  --creation-token \"nfsv41-kerberos-volume\" \\"
    echo "  --protocol-types NFSv4.1 \\"
    echo "  --kerberos-enabled true \\"
    echo "  --export-policy '{\"rules\":[{\"ruleIndex\":1,\"unixReadOnly\":false,\"unixReadWrite\":true,\"kerberos5ReadWrite\":true,\"allowedClients\":\"0.0.0.0/0\"}]}'"
fi

echo ""
echo "🏁 NFSv4.1 Kerberos troubleshooting complete!"
echo "📖 Reference: https://learn.microsoft.com/azure/azure-netapp-files/troubleshoot-volumes"
