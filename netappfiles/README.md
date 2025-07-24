# Azure NetApp Files CLI Samples

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://shell.azure.com/)

This repository contains Azure CLI scripts and samples for Azure NetApp Files, organized by functionality and use case.

## 📁 Repository Structure

### 🚀 [Provisioning](./provisioning/)
Complete Azure CLI scripts for provisioning ANF resources:

- **[Accounts](./provisioning/accounts/)** - NetApp Files account creation and management
- **[Capacity Pools](./provisioning/capacity-pools/)** - Capacity pool provisioning with different service levels
- **[Volumes](./provisioning/volumes/)** - Volume creation, configuration, and management
- **[Snapshots](./provisioning/snapshots/)** - Snapshot policies and manual snapshot creation
- **[Backups](./provisioning/backups/)** - Backup configuration and management
- **[Cross-Region Replication](./provisioning/cross-region-replication/)** - CRR setup and management

### 📊 [Metrics](./metrics/)
Azure CLI scripts for monitoring and metrics collection:

- **[Performance Monitoring](./metrics/performance-monitoring/)** - Performance metrics and monitoring setup
- **[Capacity Monitoring](./metrics/capacity-monitoring/)** - Capacity utilization and alerting

### 📝 [Logs & Queries](./logs-queries/)
Log analysis and query scripts:

- **[ARG Queries](./logs-queries/arg-queries/)** - Azure Resource Graph queries for ANF resources
- **[Diagnostic Logs](./logs-queries/diagnostic-logs/)** - Diagnostic settings and log analysis

### 🔧 [Troubleshooting](./troubleshooting/)
Diagnostic and troubleshooting scripts:

- **[Connectivity](./troubleshooting/connectivity/)** - Network connectivity troubleshooting
- **[Performance](./troubleshooting/performance/)** - Performance issue diagnosis
- **[Backup & Restore](./troubleshooting/backup-restore/)** - Backup and restore troubleshooting

### 💰 [Billing](./billing/)
Cost management and billing analysis scripts:

- **[Cost Analysis](./billing/anf-cost-analysis.sh)** - Comprehensive cost analysis and optimization
- **[Budget Management](./billing/anf-budget-management.sh)** - Budget creation, monitoring, and alerts

### 🔄 [CRUD Operations](./crud-operations/)
Complete Create, Read, Update, Delete operations for all ANF resources:

- **[List](./crud-operations/list/)** - List and query all ANF resources with filtering
- **[Show](./crud-operations/show/)** - Detailed resource information with mount instructions
- **[Update](./crud-operations/update/)** - Modify existing resources (resize, service levels, etc.)
- **[Delete](./crud-operations/delete/)** - Safe deletion with backup options and cleanup

### 🏗️ [Solution Architectures](./solution-architectures/)
End-to-end solution examples with Azure CLI automation:

- **[AVS Datastores](./solution-architectures/avs-datastores/)** - Azure VMware Solution with ANF datastores
- **[HPC Workloads](./solution-architectures/hpc-workloads/)** - High-performance computing scenarios
- **[Database Workloads](./solution-architectures/database-workloads/)** - Database storage solutions

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and configured
- Azure subscription with NetApp Files service enabled
- Appropriate permissions for resource creation

### Basic Usage

1. **Create a NetApp Files account:**
   ```bash
   cd provisioning/accounts
   ./create-netapp-account.sh
   ```

2. **Create a capacity pool:**
   ```bash
   cd provisioning/capacity-pools
   ./create-capacity-pool.sh
   ```

3. **Create a volume:**
   ```bash
   cd provisioning/volumes
   ./create-volume.sh
   ```

### Advanced Scenarios

1. **Set up AVS with ANF datastores:**
   ```bash
   cd solution-architectures/avs-datastores
   ./provision-avs-anf-datastore.sh
   ```

2. **Troubleshoot connectivity issues:**
   ```bash
   cd troubleshooting/connectivity
   ./anf-connectivity-troubleshoot.sh
   ```

3. **Query ANF resources across subscriptions:**
   ```bash
   cd logs-queries/arg-queries
   ./anf-resource-graph-queries.sh
   ```

4. **Analyze costs and create budgets:**
   ```bash
   cd billing
   ./anf-cost-analysis.sh -c  # Current resource costs
   ./anf-budget-management.sh create --name monthly-budget --amount 1000 --rg myRG --emails admin@company.com
   ```

5. **Manage resources with CRUD operations:**
   ```bash
   cd crud-operations
   ./list/anf-list-all.sh all --rg myRG  # List all resources
   ./update/anf-update-resources.sh resize-volume --account myAccount --pool myPool --volume myVolume --rg myRG --size 214748364800
   ```

## 📋 Common Use Cases

### Volume Management
- [Create NFS volume](./provisioning/volumes/) for Linux workloads
- [Create SMB volume](./provisioning/volumes/) for Windows workloads
- [Configure snapshots](./provisioning/snapshots/) for data protection
- [Set up backups](./provisioning/backups/) for long-term retention

### Performance Optimization
- [Monitor performance metrics](./metrics/performance-monitoring/)
- [Troubleshoot performance issues](./troubleshooting/performance/)
- [Optimize service levels](./provisioning/capacity-pools/)

### Enterprise Solutions
- [AVS datastores](./solution-architectures/avs-datastores/) for VMware workloads
- [HPC storage](./solution-architectures/hpc-workloads/) for compute clusters
- [Database storage](./solution-architectures/database-workloads/) for enterprise databases

## 🔧 Configuration

Most scripts use environment variables or command-line parameters. Common variables:

```bash
# Resource Configuration
RESOURCE_GROUP="your-anf-rg"
LOCATION="East US"
NETAPP_ACCOUNT="your-anf-account"
CAPACITY_POOL="your-pool"
VOLUME_NAME="your-volume"

# Network Configuration
VNET_NAME="your-vnet"
SUBNET_NAME="your-anf-subnet"
```

## 🎯 Best Practices

### Security
- Use dedicated subnets with proper delegation
- Configure export policies restrictively
- Implement Network Security Groups (NSG) rules
- Enable diagnostic logging

### Performance
- Choose appropriate service levels (Standard/Premium/Ultra)
- Size volumes according to performance requirements
- Use optimal mount options for your workload
- Monitor performance metrics regularly

### Cost Optimization
- Right-size capacity pools and volumes
- Use snapshots for point-in-time recovery
- Implement lifecycle management policies
- Monitor capacity utilization
- [Set up cost alerts and budgets](./billing/) with automated monitoring
- [Analyze spending patterns](./billing/) to optimize service levels

### Resource Management
- [Use CRUD operations](./crud-operations/) for efficient resource management
- [Implement bulk operations](./crud-operations/update/) for large environments
- [Regular cleanup](./crud-operations/delete/) of unused resources and old snapshots
- [Export resource inventory](./crud-operations/list/) for auditing and compliance

## 📚 Documentation Links

- [Azure NetApp Files documentation](https://docs.microsoft.com/azure/azure-netapp-files/)
- [Azure CLI reference for NetApp Files](https://docs.microsoft.com/cli/azure/netappfiles)
- [Performance considerations](https://docs.microsoft.com/azure/azure-netapp-files/azure-netapp-files-performance-considerations)
- [Network planning guidelines](https://docs.microsoft.com/azure/azure-netapp-files/azure-netapp-files-network-topologies)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your script with proper documentation
4. Test thoroughly in a development environment
5. Submit a pull request

### Script Standards
- Include comprehensive error handling
- Add detailed comments explaining each step
- Use consistent variable naming
- Include cleanup instructions
- Test with different configurations

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

These scripts are provided as examples and should be thoroughly tested in a development environment before use in production. Always review and modify scripts according to your specific requirements and security policies.

---

**Last Updated:** July 2025  
**Maintained by:** Azure NetApp Files Team
|[create-netapp-account](./create-netapp-account/)|Creates a NetApp account with the basic configuration required for Azure NetApp Files|
|[create-capacity-pool](./create-capacity-pool/)|Creates a capacity pool within a NetApp account to allocate storage capacity|
|[create-volume](./create-volume/)|Creates a NetApp volume with NFS protocol support for file sharing|
|[volume-snapshots](./volume-snapshots/)|Creates and manages snapshots of NetApp volumes for backup and recovery|
|[cross-region-replication](./cross-region-replication/)|Sets up cross-region replication for disaster recovery and data protection|
|[volume-backup](./volume-backup/)|Configures backup policies and manages volume backups|
|[performance-monitoring](./performance-monitoring/)|Monitors volume performance metrics and configures alerting|


## Prerequisites

- Azure CLI 2.0 or later
- Valid Azure subscription
- Azure NetApp Files enabled in your subscription
- Appropriate RBAC permissions

## Getting Started

1. Clone this repository or download the specific sample
2. Make the script executable: `chmod +x script-name.sh`
3. Run the script: `./script-name.sh`

## Common Parameters

Most samples use these common patterns:

- **Resource Group**: `msdocs-netappfiles-rg-$randomIdentifier`
- **NetApp Account**: `msdocs-netapp-account-$randomIdentifier`  
- **Location**: East US (configurable)
- **Tags**: Automatically applied for resource identification

## Best Practices

These samples follow Azure NetApp Files best practices:

- ✅ Proper subnet delegation for NetApp volumes
- ✅ Appropriate service levels for workload requirements
- ✅ Resource cleanup to avoid ongoing costs
- ✅ Error handling and validation
- ✅ Meaningful resource naming conventions

## Architecture

```text
Resource Group
├── NetApp Account
│   └── Capacity Pool(s)
│       └── Volume(s)
├── Virtual Network
│   └── Delegated Subnet
└── Supporting Resources (optional)
    ├── Backup Policies
    ├── Snapshots  
    └── Replication Relationships
```

## Service Levels

Azure NetApp Files offers three service levels:

- **Standard**: Up to 16 MiB/s per TiB
- **Premium**: Up to 64 MiB/s per TiB  
- **Ultra**: Up to 128 MiB/s per TiB

## Protocol Support

- NFSv3 and NFSv4.1
- SMB 2.1, 3.0, and 3.1.1
- Dual-protocol (NFS and SMB)

## Useful Commands

```bash
# List all NetApp accounts
az netappfiles account list --output table

# Show volume performance metrics  
az monitor metrics list --resource <volume-resource-id> --metric VolumeLogicalSize

# Create a volume snapshot
az netappfiles snapshot create --resource-group myRG --account-name myAccount --pool-name myPool --volume-name myVolume --snapshot-name mySnapshot
```

## Cost Management

💡 **Cost Tips:**
- Delete unused volumes and snapshots
- Right-size capacity pools
- Monitor throughput utilization
- Use automated backup policies

## Support

- [Azure NetApp Files documentation](https://docs.microsoft.com/azure/azure-netapp-files/)
- [Azure CLI reference](https://docs.microsoft.com/cli/azure/netappfiles) 
- [Azure support](https://azure.microsoft.com/support/)

## Contributing

These samples are part of the Azure CLI Samples repository. To contribute:

1. Follow the repository's contribution guidelines
2. Ensure scripts pass validation tests
3. Include proper documentation
4. Add appropriate tags and metadata

---

*These samples demonstrate Azure NetApp Files capabilities and are provided as educational material. Always review and test thoroughly before using in production environments.*

**Tags**: `Azure NetApp Files`, `NFS`, `SMB`, `High Performance Storage`, `Enterprise File Services`, `Azure CLI`
