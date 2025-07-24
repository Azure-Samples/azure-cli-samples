# Azure NetApp Files - Read Operations

This directory contains scripts for reading and listing Azure NetApp Files resources.

## Scripts Overview

### anf-list-all.sh
Comprehensive listing of all ANF resources with filtering and export options.

**Features:**
- List accounts, pools, volumes, snapshots, policies
- Advanced filtering by resource group, account, pool
- Multiple output formats (table, JSON, YAML, TSV)
- Resource summary with counts and utilization
- Complete JSON export for backup/documentation

**Usage Examples:**
```bash
# List all resources in a resource group
./anf-list-all.sh all --rg myResourceGroup

# List volumes in JSON format
./anf-list-all.sh volumes --format json

# Export all data to JSON file
./anf-list-all.sh export
```

### anf-show-details.sh
Detailed information about specific ANF resources with mount instructions.

**Features:**
- Detailed resource information
- Automatic NFS/SMB mount command generation
- Comprehensive account/pool/volume overview
- Multiple output format support
- Mount troubleshooting information

**Usage Examples:**
```bash
# Show account details
./anf-show-details.sh account --name myAccount --rg myRG

# Show volume with mount instructions
./anf-show-details.sh volume-mount --account myAccount --pool myPool --name myVolume --rg myRG

# Comprehensive account overview
./anf-show-details.sh comprehensive --account myAccount --rg myRG
```

## Available Commands

### List Operations (anf-list-all.sh)
- `accounts` - List NetApp accounts
- `pools` - List capacity pools
- `volumes` - List volumes
- `snapshots` - List snapshots
- `snapshot-policies` - List snapshot policies
- `backup-policies` - List backup policies
- `quotas` - List volume quotas
- `replications` - List replication connections
- `all` - Complete resource summary
- `export` - Export all data to JSON

### Show Operations (anf-show-details.sh)
- `account` - Show account details
- `pool` - Show pool details
- `volume` - Show volume details
- `volume-mount` - Show volume with mount instructions
- `snapshot` - Show snapshot details
- `snapshot-policy` - Show snapshot policy details
- `backup-policy` - Show backup policy details
- `quota-rule` - Show quota rule details
- `replication` - Show replication status
- `comprehensive` - Show all resources for an account

## Common Use Cases

### Resource Discovery
```bash
# Get complete inventory
./anf-list-all.sh all --format json > anf-inventory.json

# Find volumes by service level
./anf-list-all.sh volumes --format json | jq '.[] | select(.serviceLevel=="Premium")'
```

### Mount Information
```bash
# Get mount instructions for a volume
./anf-show-details.sh volume-mount --account myAccount --pool myPool --name myVolume --rg myRG
```

### Monitoring and Reporting
```bash
# Daily resource inventory
./anf-list-all.sh export > daily-inventory-$(date +%Y%m%d).json

# Check resource status
./anf-show-details.sh comprehensive --account myAccount --rg myRG
```

## Output Formats

All scripts support multiple output formats:
- `table` (default for list operations)
- `json` (default for show operations)
- `yaml`
- `tsv`

## Prerequisites

- Azure CLI installed and configured
- Azure NetApp Files service enabled
- Appropriate read permissions on ANF resources

For detailed usage and examples, run each script with no parameters to see the help information.
