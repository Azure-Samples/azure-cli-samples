# Azure NetApp Files - Availability Checks

This directory contains comprehensive resource availability validation scripts for Azure NetApp Files.

## 📁 Directory Structure

```
operations/availability-checks/
├── check-resource-availability.sh     # Comprehensive availability validation
└── README.md                         # This file
```

## 🚀 Quick Start

### Basic Usage

```bash
# Check account name availability
./check-resource-availability.sh check-name --name myAccount --type account --rg myResourceGroup --location eastus

# Check all availability types for a volume
./check-resource-availability.sh check-all --name myVolume --type volume --rg myResourceGroup --location eastus --subnet-id /subscriptions/.../subnets/anf-subnet

# Generate available name suggestions
./check-resource-availability.sh generate-names --base myapp --type volume --rg myResourceGroup --location eastus --count 10

# Bulk check names from file
./check-resource-availability.sh bulk-names --type account --rg myResourceGroup --location eastus --file account-names.txt
```

## 📊 Available Commands

### Name Availability Checks

Check if resource names are available:

```bash
# NetApp Account name availability
./check-resource-availability.sh check-name --name "myNetAppAccount" --type account --rg myRG --location eastus

# Capacity Pool name availability  
./check-resource-availability.sh check-name --name "myCapacityPool" --type pool --rg myRG --location eastus

# Volume name availability
./check-resource-availability.sh check-name --name "myVolume" --type volume --rg myRG --location eastus

# Snapshot name availability
./check-resource-availability.sh check-name --name "mySnapshot" --type snapshot --rg myRG --location eastus
```

### Quota Availability Checks

Check if quota is available for resources:

```bash
# Account quota availability
./check-resource-availability.sh check-quota --name "myNetAppAccount" --type account --rg myRG --location eastus

# Pool quota availability
./check-resource-availability.sh check-quota --name "myCapacityPool" --type pool --rg myRG --location eastus

# Volume quota availability
./check-resource-availability.sh check-quota --name "myVolume" --type volume --rg myRG --location eastus
```

### File Path Availability Checks

Check if file paths are available for volumes:

```bash
# Basic file path check
./check-resource-availability.sh check-file-path --path "/vol1" --subnet-id "/subscriptions/sub-id/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/anf-subnet" --location eastus

# File path check with availability zone
./check-resource-availability.sh check-file-path --path "/vol1" --subnet-id "/subscriptions/sub-id/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/anf-subnet" --location eastus --zone "1"
```

### Comprehensive Availability Checks

Check all availability types for a resource:

```bash
# Complete account availability check
./check-resource-availability.sh check-all --name "myNetAppAccount" --type account --rg myRG --location eastus

# Complete volume availability check (includes file path)
./check-resource-availability.sh check-all --name "myVolume" --type volume --rg myRG --location eastus --subnet-id "/subscriptions/.../subnets/anf-subnet"

# Volume availability check with availability zone
./check-resource-availability.sh check-all --name "myVolume" --type volume --rg myRG --location eastus --subnet-id "/subscriptions/.../subnets/anf-subnet" --zone "2"
```

### Bulk Operations

#### Bulk Name Checking

Create a text file with names to check:

```bash
# Create names file
cat > account-names.txt << EOF
myaccount1
myaccount2
myaccount3
production-account
development-account
EOF

# Bulk check all names
./check-resource-availability.sh bulk-names --type account --rg myRG --location eastus --file account-names.txt
```

#### Name Generation

Generate available name suggestions:

```bash
# Generate 5 available names based on "myapp"
./check-resource-availability.sh generate-names --base myapp --type volume --rg myRG --location eastus

# Generate 10 available names
./check-resource-availability.sh generate-names --base webapp --type account --rg myRG --location eastus --count 10

# Generate names for capacity pools
./check-resource-availability.sh generate-names --base prodpool --type pool --rg myRG --location eastus --count 5
```

## 🔍 Resource Types

The script supports checking availability for all Azure NetApp Files resource types:

### Supported Resource Types

| Type | Description | Name Check | Quota Check | File Path Check |
|------|-------------|------------|-------------|-----------------|
| `account` | NetApp Account | ✅ | ✅ | ❌ |
| `pool` | Capacity Pool | ✅ | ✅ | ❌ |
| `volume` | Volume | ✅ | ✅ | ✅ |
| `snapshot` | Snapshot | ✅ | ❌ | ❌ |

### Azure CLI Commands Used

The script uses these Azure CLI commands:

- `az netappfiles check-name-availability`
- `az netappfiles check-quota-availability`  
- `az netappfiles check-file-path-availability`

## 📝 Command Reference

### Global Options

| Option | Description | Required |
|--------|-------------|----------|
| `--name NAME` | Resource name to check | Yes (for most commands) |
| `--type TYPE` | Resource type (account/pool/volume/snapshot) | Yes |
| `--rg RG` | Resource group name | Yes |
| `--location LOCATION` | Azure location | Yes |

### Additional Options

| Option | Description | Used With |
|--------|-------------|-----------|
| `--subnet-id ID` | Subnet resource ID | File path checks, volume checks |
| `--zone ZONE` | Availability zone | File path checks |
| `--file FILE` | File containing names to check | Bulk operations |
| `--count COUNT` | Number of suggestions to generate | Name generation |
| `--base NAME` | Base name for generation | Name generation |
| `--days DAYS` | Number of days (if applicable) | Some operations |

## 💡 Examples by Scenario

### 1. Planning New NetApp Account

```bash
# Check if preferred account name is available
./check-resource-availability.sh check-name --name "prod-netapp-account" --type account --rg production-rg --location eastus

# If not available, generate alternatives
./check-resource-availability.sh generate-names --base prod-netapp --type account --rg production-rg --location eastus --count 5

# Do comprehensive check
./check-resource-availability.sh check-all --name "prod-netapp-account-01" --type account --rg production-rg --location eastus
```

### 2. Volume Deployment Planning

```bash
# Check complete volume availability including file path
./check-resource-availability.sh check-all \
  --name "webapp-volume" \
  --type volume \
  --rg webapp-rg \
  --location eastus \
  --subnet-id "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/webapp-vnet/subnets/anf-subnet"

# Check with specific availability zone
./check-resource-availability.sh check-all \
  --name "webapp-volume" \
  --type volume \
  --rg webapp-rg \
  --location eastus \
  --subnet-id "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/webapp-vnet/subnets/anf-subnet" \
  --zone "1"
```

### 3. Bulk Resource Planning

```bash
# Create a list of planned volume names
cat > volume-names.txt << EOF
vol-web-01
vol-web-02
vol-db-01
vol-db-02
vol-cache-01
EOF

# Check availability of all names
./check-resource-availability.sh bulk-names --type volume --rg production-rg --location eastus --file volume-names.txt
```

### 4. Automated Name Generation

```bash
# Generate available names for different environments
./check-resource-availability.sh generate-names --base prod --type account --rg production-rg --location eastus --count 3
./check-resource-availability.sh generate-names --base dev --type account --rg development-rg --location eastus --count 3
./check-resource-availability.sh generate-names --base test --type account --rg testing-rg --location eastus --count 3
```

## 🚨 Understanding Results

### Name Availability Results

```bash
=== Account Name Availability Check ===
Account Name: myaccount
Available: true
Reason: N/A
Message: N/A
```

### Quota Availability Results

```bash
=== Account Quota Availability Check ===
Account Name: myaccount
Available: true
Reason: N/A
Message: N/A
```

### File Path Availability Results

```bash
=== File Path Availability Check ===
File Path: /vol1
Subnet ID: /subscriptions/.../subnets/anf-subnet
Location: eastus
Available: true
Reason: N/A
Message: N/A
```

### Comprehensive Results

```bash
=== Comprehensive Availability Summary ===
Resource: myvolume
Type: volume
Name Available: ✓ Yes
Quota Available: ✓ Yes
File Path Available: ✓ Yes

Overall Status: ✓ Available
```

## 🔧 Integration with Automation

This availability check script is integrated with the main ANF automation system:

### In Script Generation
```bash
# The comprehensive script generator includes availability checks
python anf_comprehensive_script_generator.py
```

### In Job Runner
```bash
# The job runner validates availability before creating resources
python anf_comprehensive_job_runner.py
```

### In Complete Automation
```bash
# The complete automation includes availability validation
python run_complete_anf_automation.py
```

## 🆘 Troubleshooting

### Common Issues

1. **Invalid Resource Type**
   ```
   Error: Invalid resource type for name check: invalid_type
   ```
   Use: account, pool, volume, or snapshot

2. **Missing Required Parameters**
   ```
   Error: Resource name, type, resource group, and location are required
   ```
   Ensure all required parameters are provided

3. **Invalid Subnet ID Format**
   ```
   Error: Failed to check file path availability
   ```
   Verify subnet ID format: `/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualNetworks/.../subnets/...`

4. **Azure CLI Authentication**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

### Debug Mode

Enable verbose logging:
```bash
set -x  # Add to script or run with bash -x
./check-resource-availability.sh check-all --name test --type account --rg myRG --location eastus
```

## 📊 Output Files

The script generates several output files:

- `anf-availability-checks-YYYYMMDD-HHMMSS.log` - Detailed execution log
- Generated name suggestions are displayed in console
- Bulk check results are displayed in formatted tables

## 🔗 Related Resources

- [Azure NetApp Files Documentation](https://docs.microsoft.com/en-us/azure/azure-netapp-files/)
- [Azure CLI NetApp Files Reference](https://docs.microsoft.com/en-us/cli/azure/netappfiles/)
- [Azure Resource Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)

---

**Note:** This availability validation system ensures proper resource planning and prevents naming conflicts during Azure NetApp Files deployment.
