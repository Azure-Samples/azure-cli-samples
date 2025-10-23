# Azure NetApp Files Authentication Troubleshooting

This directory contains scripts for troubleshooting Azure NetApp Files authentication issues.

## Scripts

### anf-ldap-kerberos-troubleshoot.sh

Comprehensive troubleshooting script for Azure NetApp Files LDAP and Kerberos authentication issues.

#### Features
- Active Directory connection validation
- DNS resolution testing for AD servers  
- LDAP connectivity testing (ports 389, 636, 3268, 3269)
- Kerberos connectivity testing (ports 88, 464)
- Volume-specific authentication settings analysis
- SMB authentication configuration checks
- Comprehensive troubleshooting recommendations
- Manual testing scenarios for authentication verification

#### Requirements
- **Azure CLI**: Version 2.30.0 or later
- **Extensions**: None (uses core Azure CLI commands)
- **Shell**: bash
- **Dependencies**: `jq` for JSON processing, `nslookup` for DNS testing (optional)

#### Testing Information
- **Last tested**: 2025-01-24
- **Test method**: Validated on Azure Cloud Shell and Windows Subsystem for Linux
- **Test platforms**: 
  - ✅ Azure Cloud Shell
  - ✅ Windows Subsystem for Linux
  - ✅ Linux
  - ✅ macOS (via bash)

#### Usage

1. **Set environment variables** (recommended):
   ```bash
   export ANF_RESOURCE_GROUP="your-resource-group"
   export ANF_ACCOUNT="your-netapp-account"
   export ANF_VOLUME="your-volume-name"
   export ANF_POOL="your-capacity-pool"
   ```

2. **Run the script**:
   ```bash
   ./anf-ldap-kerberos-troubleshoot.sh
   ```

3. **Review output** for authentication issues and recommendations

#### Script Capabilities

The script automatically:
- Detects Azure subscription ID
- Validates Active Directory connections
- Tests DNS resolution for domain controllers
- Checks LDAP and Kerberos port connectivity
- Analyzes volume authentication settings
- Provides security recommendations (LDAP signing, TLS, AES encryption)
- Offers manual testing commands for verification

#### Security Best Practices

The script promotes these security configurations:
- LDAP signing enabled
- LDAP over TLS enabled  
- AES encryption for Kerberos
- SMB encryption enabled
- Proper organizational unit placement

#### Troubleshooting Coverage

Common issues addressed:
- Active Directory connection failures
- DNS resolution problems
- LDAP connectivity issues
- Kerberos authentication failures
- SMB/CIFS access problems
- Dual-protocol volume authentication
- Network security group blocking
- Firewall connectivity issues

#### Sample Output

```
🔐 Azure NetApp Files LDAP & Kerberos Authentication Troubleshooting
==================================================================
🔍 Detecting subscription ID...
📍 Using subscription: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

🏢 Checking Active Directory connection...
✅ Active Directory connections found:
[
  {
    "Domain": "contoso.com",
    "DNS": "10.0.0.4,10.0.0.5",
    "LdapSigning": true,
    "AesEncryption": true
  }
]

🌐 Testing DNS resolution...
📡 Testing DNS server: 10.0.0.4
  ✅ Port 53 accessible on 10.0.0.4
  ✅ Domain contoso.com resolves via 10.0.0.4
```

For complete troubleshooting guidance, run the script and follow the comprehensive recommendations provided.
