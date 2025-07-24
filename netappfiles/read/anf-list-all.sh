#!/bin/bash
# Azure NetApp Files - Comprehensive List Operations
# List all ANF resources with detailed information and filtering options

set -e

# Configuration
SCRIPT_NAME="ANF List Operations"
LOG_FILE="anf-list-operations-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}" | tee -a "$LOG_FILE"
}

# Function to check Azure CLI login
check_azure_login() {
    if ! az account show &>/dev/null; then
        error "Not logged into Azure CLI. Please run 'az login' first."
        exit 1
    fi
    log "Azure CLI authentication verified"
}

# Function to list all NetApp accounts
list_accounts() {
    local resource_group="$1"
    local output_format="${2:-table}"
    
    info "Listing NetApp accounts..."
    
    if [ ! -z "$resource_group" ]; then
        log "Filtering by resource group: $resource_group"
        az netappfiles account list \
            --resource-group "$resource_group" \
            --query "[].{Name:name,ResourceGroup:resourceGroup,Location:location,ProvisioningState:provisioningState,ActiveDirectory:activeDirectories[0].activeDirectoryId,Tags:tags}" \
            --output "$output_format"
    else
        az netappfiles account list \
            --query "[].{Name:name,ResourceGroup:resourceGroup,Location:location,ProvisioningState:provisioningState,ActiveDirectory:activeDirectories[0].activeDirectoryId,Tags:tags}" \
            --output "$output_format"
    fi
}

# Function to list all capacity pools
list_pools() {
    local account_name="$1"
    local resource_group="$2"
    local output_format="${3:-table}"
    
    info "Listing capacity pools..."
    
    if [ ! -z "$account_name" ] && [ ! -z "$resource_group" ]; then
        log "Filtering by account: $account_name in resource group: $resource_group"
        az netappfiles pool list \
            --account-name "$account_name" \
            --resource-group "$resource_group" \
            --query "[].{Account:accountName,Pool:name,Size:size,ServiceLevel:serviceLevel,QosType:qosType,Utilized:utilizedSize,Available:size-utilizedSize,ProvisioningState:provisioningState,Tags:tags}" \
            --output "$output_format"
    elif [ ! -z "$account_name" ]; then
        error "Resource group is required when account name is specified"
        return 1
    else
        az netappfiles pool list \
            --query "[].{Account:accountName,Pool:name,Size:size,ServiceLevel:serviceLevel,QosType:qosType,Utilized:utilizedSize,Available:size-utilizedSize,ProvisioningState:provisioningState,Tags:tags}" \
            --output "$output_format"
    fi
}

# Function to list all volumes
list_volumes() {
    local account_name="$1"
    local pool_name="$2"
    local resource_group="$3"
    local output_format="${4:-table}"
    
    info "Listing volumes..."
    
    if [ ! -z "$account_name" ] && [ ! -z "$pool_name" ] && [ ! -z "$resource_group" ]; then
        log "Filtering by pool: $pool_name in account: $account_name"
        az netappfiles volume list \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --resource-group "$resource_group" \
            --query "[].{Account:accountName,Pool:poolName,Volume:name,Size:usageThreshold,ServiceLevel:serviceLevel,Protocol:protocolTypes,State:provisioningState,FileSystemId:fileSystemId,MountTargets:mountTargets[0].ipAddress,Tags:tags}" \
            --output "$output_format"
    elif [ ! -z "$account_name" ] && [ ! -z "$resource_group" ]; then
        log "Filtering by account: $account_name"
        az netappfiles volume list \
            --account-name "$account_name" \
            --resource-group "$resource_group" \
            --query "[].{Account:accountName,Pool:poolName,Volume:name,Size:usageThreshold,ServiceLevel:serviceLevel,Protocol:protocolTypes,State:provisioningState,FileSystemId:fileSystemId,MountTargets:mountTargets[0].ipAddress,Tags:tags}" \
            --output "$output_format"
    else
        az netappfiles volume list \
            --query "[].{Account:accountName,Pool:poolName,Volume:name,Size:usageThreshold,ServiceLevel:serviceLevel,Protocol:protocolTypes,State:provisioningState,FileSystemId:fileSystemId,MountTargets:mountTargets[0].ipAddress,Tags:tags}" \
            --output "$output_format"
    fi
}

# Function to list snapshots
list_snapshots() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local output_format="${5:-table}"
    
    info "Listing snapshots..."
    
    if [ ! -z "$account_name" ] && [ ! -z "$pool_name" ] && [ ! -z "$volume_name" ] && [ ! -z "$resource_group" ]; then
        log "Filtering by volume: $volume_name"
        az netappfiles snapshot list \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --resource-group "$resource_group" \
            --query "[].{Volume:volumeName,Snapshot:name,Created:created,Size:usageThreshold,ProvisioningState:provisioningState}" \
            --output "$output_format"
    else
        warn "Account name, pool name, volume name, and resource group are required for listing snapshots"
        return 1
    fi
}

# Function to list snapshot policies
list_snapshot_policies() {
    local account_name="$1"
    local resource_group="$2"
    local output_format="${3:-table}"
    
    info "Listing snapshot policies..."
    
    if [ ! -z "$account_name" ] && [ ! -z "$resource_group" ]; then
        az netappfiles snapshot policy list \
            --account-name "$account_name" \
            --resource-group "$resource_group" \
            --query "[].{Account:accountName,Policy:name,Enabled:enabled,HourlySnapshots:hourlySchedule.snapshotsToKeep,DailySnapshots:dailySchedule.snapshotsToKeep,WeeklySnapshots:weeklySchedule.snapshotsToKeep,MonthlySnapshots:monthlySchedule.snapshotsToKeep,ProvisioningState:provisioningState}" \
            --output "$output_format"
    else
        warn "Account name and resource group are required for listing snapshot policies"
        return 1
    fi
}

# Function to list backup policies
list_backup_policies() {
    local account_name="$1"
    local resource_group="$2"
    local output_format="${3:-table}"
    
    info "Listing backup policies..."
    
    if [ ! -z "$account_name" ] && [ ! -z "$resource_group" ]; then
        az netappfiles backup policy list \
            --account-name "$account_name" \
            --resource-group "$resource_group" \
            --query "[].{Account:accountName,Policy:name,Enabled:enabled,DailyBackups:dailyBackupsToKeep,WeeklyBackups:weeklyBackupsToKeep,MonthlyBackups:monthlyBackupsToKeep,ProvisioningState:provisioningState}" \
            --output "$output_format"
    else
        warn "Account name and resource group are required for listing backup policies"
        return 1
    fi
}

# Function to list volume quotas
list_volume_quotas() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local output_format="${5:-table}"
    
    info "Listing volume quotas..."
    
    if [ ! -z "$account_name" ] && [ ! -z "$pool_name" ] && [ ! -z "$volume_name" ] && [ ! -z "$resource_group" ]; then
        az netappfiles volume quota-rule list \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --resource-group "$resource_group" \
            --query "[].{Volume:volumeName,QuotaRule:name,Type:type,Target:quotaTarget,Size:quotaSizeInKiBs,ProvisioningState:provisioningState}" \
            --output "$output_format"
    else
        warn "Account name, pool name, volume name, and resource group are required for listing volume quotas"
        return 1
    fi
}

# Function to list replication connections
list_replications() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local output_format="${5:-table}"
    
    info "Listing replication connections..."
    
    if [ ! -z "$account_name" ] && [ ! -z "$pool_name" ] && [ ! -z "$volume_name" ] && [ ! -z "$resource_group" ]; then
        az netappfiles volume replication show \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --resource-group "$resource_group" \
            --query "{Volume:volumeName,RemoteVolumeResourceId:remoteVolumeResourceId,ReplicationSchedule:replicationSchedule,EndpointType:endpointType,ReplicationStatus:mirrorState}" \
            --output "$output_format"
    else
        warn "Account name, pool name, volume name, and resource group are required for listing replications"
        return 1
    fi
}

# Function to list all resources with summary
list_all_summary() {
    local resource_group="$1"
    local output_format="${2:-table}"
    
    log "Generating comprehensive ANF resource summary"
    
    echo -e "\n${BLUE}=== Azure NetApp Files Resource Summary ===${NC}"
    
    # Count resources
    local account_count=$(az netappfiles account list ${resource_group:+--resource-group "$resource_group"} --query "length(@)" --output tsv)
    local pool_count=$(az netappfiles pool list --query "length(@)" --output tsv)
    local volume_count=$(az netappfiles volume list --query "length(@)" --output tsv)
    
    echo -e "\n${GREEN}Resource Counts:${NC}"
    echo "NetApp Accounts: $account_count"
    echo "Capacity Pools: $pool_count"
    echo "Volumes: $volume_count"
    
    echo -e "\n${GREEN}NetApp Accounts:${NC}"
    list_accounts "$resource_group" "$output_format"
    
    echo -e "\n${GREEN}Capacity Pools:${NC}"
    list_pools "" "" "$output_format"
    
    echo -e "\n${GREEN}Volumes:${NC}"
    list_volumes "" "" "" "$output_format"
}

# Function to export all data to JSON
export_all_data() {
    local output_file="anf-resources-export-$(date +%Y%m%d-%H%M%S).json"
    
    log "Exporting all ANF data to $output_file"
    
    # Create comprehensive JSON export
    cat > "$output_file" <<EOF
{
    "exportDate": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "accounts": $(az netappfiles account list --output json),
    "pools": $(az netappfiles pool list --output json),
    "volumes": $(az netappfiles volume list --output json)
}
EOF
    
    log "Export completed: $output_file"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  accounts [--rg RG] [--format FORMAT]     List NetApp accounts"
    echo "  pools [--account ACCOUNT] [--rg RG]      List capacity pools"
    echo "  volumes [--account ACCOUNT] [--pool POOL] [--rg RG]  List volumes"
    echo "  snapshots --account ACCOUNT --pool POOL --volume VOLUME --rg RG  List snapshots"
    echo "  snapshot-policies --account ACCOUNT --rg RG  List snapshot policies"
    echo "  backup-policies --account ACCOUNT --rg RG    List backup policies"
    echo "  quotas --account ACCOUNT --pool POOL --volume VOLUME --rg RG  List volume quotas"
    echo "  replications --account ACCOUNT --pool POOL --volume VOLUME --rg RG  List replications"
    echo "  all [--rg RG] [--format FORMAT]         List all resources with summary"
    echo "  export                                   Export all data to JSON"
    echo ""
    echo "Options:"
    echo "  --rg, --resource-group RG               Resource group filter"
    echo "  --account ACCOUNT                       NetApp account name"
    echo "  --pool POOL                            Capacity pool name"
    echo "  --volume VOLUME                        Volume name"
    echo "  --format FORMAT                        Output format (table, json, yaml, tsv)"
    echo ""
    echo "Examples:"
    echo "  $0 accounts --rg myRG                   # List accounts in resource group"
    echo "  $0 pools --account myAccount --rg myRG  # List pools in account"
    echo "  $0 volumes --format json                # List all volumes in JSON format"
    echo "  $0 all --rg myRG                       # Complete summary for resource group"
}

# Main function
main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    check_azure_login
    
    local command="$1"
    shift
    
    # Parse command line arguments
    local resource_group=""
    local account_name=""
    local pool_name=""
    local volume_name=""
    local output_format="table"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --rg|--resource-group)
                resource_group="$2"
                shift 2
                ;;
            --account)
                account_name="$2"
                shift 2
                ;;
            --pool)
                pool_name="$2"
                shift 2
                ;;
            --volume)
                volume_name="$2"
                shift 2
                ;;
            --format)
                output_format="$2"
                shift 2
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log "Starting $SCRIPT_NAME - Command: $command"
    
    case "$command" in
        accounts)
            list_accounts "$resource_group" "$output_format"
            ;;
        pools)
            list_pools "$account_name" "$resource_group" "$output_format"
            ;;
        volumes)
            list_volumes "$account_name" "$pool_name" "$resource_group" "$output_format"
            ;;
        snapshots)
            list_snapshots "$account_name" "$pool_name" "$volume_name" "$resource_group" "$output_format"
            ;;
        snapshot-policies)
            list_snapshot_policies "$account_name" "$resource_group" "$output_format"
            ;;
        backup-policies)
            list_backup_policies "$account_name" "$resource_group" "$output_format"
            ;;
        quotas)
            list_volume_quotas "$account_name" "$pool_name" "$volume_name" "$resource_group" "$output_format"
            ;;
        replications)
            list_replications "$account_name" "$pool_name" "$volume_name" "$resource_group" "$output_format"
            ;;
        all)
            list_all_summary "$resource_group" "$output_format"
            ;;
        export)
            export_all_data
            ;;
        *)
            error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
    
    log "$SCRIPT_NAME completed successfully"
}

# Run main function with all arguments
main "$@"
