#!/bin/bash
# Azure NetApp Files - Show/Get Operations
# Get detailed information about specific ANF resources

set -e

# Configuration
SCRIPT_NAME="ANF Show Operations"
LOG_FILE="anf-show-operations-$(date +%Y%m%d-%H%M%S).log"

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

# Function to show NetApp account details
show_account() {
    local account_name="$1"
    local resource_group="$2"
    local output_format="${3:-json}"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "Account name and resource group are required"
        return 1
    fi
    
    info "Getting details for NetApp account: $account_name"
    
    az netappfiles account show \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to show capacity pool details
show_pool() {
    local account_name="$1"
    local pool_name="$2"
    local resource_group="$3"
    local output_format="${4:-json}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, and resource group are required"
        return 1
    fi
    
    info "Getting details for capacity pool: $pool_name"
    
    az netappfiles pool show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to show volume details
show_volume() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local output_format="${5:-json}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Getting details for volume: $volume_name"
    
    az netappfiles volume show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to show volume with mount instructions
show_volume_with_mount() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Getting volume details with mount instructions: $volume_name"
    
    # Get volume details
    local volume_data=$(az netappfiles volume show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --output json)
    
    # Extract mount information
    local mount_ip=$(echo "$volume_data" | jq -r '.mountTargets[0].ipAddress // "N/A"')
    local file_path=$(echo "$volume_data" | jq -r '.filePath // "N/A"')
    local protocol=$(echo "$volume_data" | jq -r '.protocolTypes[0] // "N/A"')
    local service_level=$(echo "$volume_data" | jq -r '.serviceLevel // "N/A"')
    local size=$(echo "$volume_data" | jq -r '.usageThreshold // "N/A"')
    
    echo -e "\n${BLUE}=== Volume Details ===${NC}"
    echo "Volume Name: $volume_name"
    echo "Service Level: $service_level"
    echo "Size: $size bytes"
    echo "Protocol: $protocol"
    echo "Mount IP: $mount_ip"
    echo "File Path: $file_path"
    
    if [ "$mount_ip" != "N/A" ] && [ "$file_path" != "N/A" ]; then
        echo -e "\n${GREEN}=== Mount Instructions ===${NC}"
        
        if [[ "$protocol" == *"NFSv3"* ]] || [[ "$protocol" == *"NFSv4.1"* ]]; then
            echo "NFS Mount Command:"
            echo "sudo mount -t nfs -o rw,hard,rsize=65536,wsize=65536,vers=3,tcp $mount_ip:/$file_path /mnt/anf"
            echo ""
            echo "Add to /etc/fstab for persistent mount:"
            echo "$mount_ip:/$file_path /mnt/anf nfs rw,hard,rsize=65536,wsize=65536,vers=3,tcp 0 0"
        fi
        
        if [[ "$protocol" == *"SMB"* ]]; then
            echo "SMB Mount Command (Windows):"
            echo "net use Z: \\\\$mount_ip\\$file_path"
            echo ""
            echo "SMB Mount Command (Linux):"
            echo "sudo mount -t cifs //$mount_ip/$file_path /mnt/anf -o username=<user>,password=<pass>"
        fi
    fi
    
    echo -e "\n${BLUE}=== Full Volume JSON ===${NC}"
    echo "$volume_data" | jq .
}

# Function to show snapshot details
show_snapshot() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local snapshot_name="$4"
    local resource_group="$5"
    local output_format="${6:-json}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$snapshot_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, snapshot name, and resource group are required"
        return 1
    fi
    
    info "Getting details for snapshot: $snapshot_name"
    
    az netappfiles snapshot show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --snapshot-name "$snapshot_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to show snapshot policy details
show_snapshot_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local output_format="${4:-json}"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ]; then
        error "Account name, policy name, and resource group are required"
        return 1
    fi
    
    info "Getting details for snapshot policy: $policy_name"
    
    az netappfiles snapshot policy show \
        --account-name "$account_name" \
        --snapshot-policy-name "$policy_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to show backup policy details
show_backup_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local output_format="${4:-json}"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ]; then
        error "Account name, policy name, and resource group are required"
        return 1
    fi
    
    info "Getting details for backup policy: $policy_name"
    
    az netappfiles backup policy show \
        --account-name "$account_name" \
        --backup-policy-name "$policy_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to show volume quota rule details
show_quota_rule() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local quota_rule_name="$4"
    local resource_group="$5"
    local output_format="${6:-json}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$quota_rule_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, quota rule name, and resource group are required"
        return 1
    fi
    
    info "Getting details for quota rule: $quota_rule_name"
    
    az netappfiles volume quota-rule show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --quota-rule-name "$quota_rule_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to show replication status
show_replication() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local output_format="${5:-json}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Getting replication status for volume: $volume_name"
    
    az netappfiles volume replication show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to show comprehensive resource details
show_comprehensive() {
    local account_name="$1"
    local resource_group="$2"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "Account name and resource group are required"
        return 1
    fi
    
    log "Generating comprehensive details for account: $account_name"
    
    echo -e "\n${BLUE}=== NetApp Account Details ===${NC}"
    show_account "$account_name" "$resource_group" "table"
    
    echo -e "\n${BLUE}=== Capacity Pools ===${NC}"
    az netappfiles pool list \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --query "[].{Name:name,Size:size,ServiceLevel:serviceLevel,QosType:qosType,Utilized:utilizedSize,Available:size-utilizedSize,State:provisioningState}" \
        --output table
    
    echo -e "\n${BLUE}=== Volumes ===${NC}"
    az netappfiles volume list \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --query "[].{Pool:poolName,Volume:name,Size:usageThreshold,ServiceLevel:serviceLevel,Protocol:protocolTypes,MountIP:mountTargets[0].ipAddress,State:provisioningState}" \
        --output table
    
    echo -e "\n${BLUE}=== Snapshot Policies ===${NC}"
    az netappfiles snapshot policy list \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --query "[].{Policy:name,Enabled:enabled,Hourly:hourlySchedule.snapshotsToKeep,Daily:dailySchedule.snapshotsToKeep,Weekly:weeklySchedule.snapshotsToKeep,Monthly:monthlySchedule.snapshotsToKeep}" \
        --output table
    
    echo -e "\n${BLUE}=== Backup Policies ===${NC}"
    az netappfiles backup policy list \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --query "[].{Policy:name,Enabled:enabled,Daily:dailyBackupsToKeep,Weekly:weeklyBackupsToKeep,Monthly:monthlyBackupsToKeep}" \
        --output table
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  account --name NAME --rg RG [--format FORMAT]"
    echo "  pool --account ACCOUNT --name NAME --rg RG [--format FORMAT]"
    echo "  volume --account ACCOUNT --pool POOL --name NAME --rg RG [--format FORMAT]"
    echo "  volume-mount --account ACCOUNT --pool POOL --name NAME --rg RG"
    echo "  snapshot --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG"
    echo "  snapshot-policy --account ACCOUNT --name NAME --rg RG"
    echo "  backup-policy --account ACCOUNT --name NAME --rg RG"
    echo "  quota-rule --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG"
    echo "  replication --account ACCOUNT --pool POOL --volume VOLUME --rg RG"
    echo "  comprehensive --account ACCOUNT --rg RG"
    echo ""
    echo "Options:"
    echo "  --name NAME                     Resource name"
    echo "  --account ACCOUNT              NetApp account name"
    echo "  --pool POOL                    Capacity pool name"
    echo "  --volume VOLUME                Volume name"
    echo "  --rg, --resource-group RG      Resource group"
    echo "  --format FORMAT                Output format (table, json, yaml, tsv)"
    echo ""
    echo "Examples:"
    echo "  $0 account --name myAccount --rg myRG"
    echo "  $0 volume-mount --account myAccount --pool myPool --name myVolume --rg myRG"
    echo "  $0 comprehensive --account myAccount --rg myRG"
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
    local resource_name=""
    local account_name=""
    local pool_name=""
    local volume_name=""
    local resource_group=""
    local output_format="json"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                resource_name="$2"
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
            --rg|--resource-group)
                resource_group="$2"
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
        account)
            show_account "$resource_name" "$resource_group" "$output_format"
            ;;
        pool)
            show_pool "$account_name" "$resource_name" "$resource_group" "$output_format"
            ;;
        volume)
            show_volume "$account_name" "$pool_name" "$resource_name" "$resource_group" "$output_format"
            ;;
        volume-mount)
            show_volume_with_mount "$account_name" "$pool_name" "$resource_name" "$resource_group"
            ;;
        snapshot)
            show_snapshot "$account_name" "$pool_name" "$volume_name" "$resource_name" "$resource_group" "$output_format"
            ;;
        snapshot-policy)
            show_snapshot_policy "$account_name" "$resource_name" "$resource_group" "$output_format"
            ;;
        backup-policy)
            show_backup_policy "$account_name" "$resource_name" "$resource_group" "$output_format"
            ;;
        quota-rule)
            show_quota_rule "$account_name" "$pool_name" "$volume_name" "$resource_name" "$resource_group" "$output_format"
            ;;
        replication)
            show_replication "$account_name" "$pool_name" "$resource_name" "$resource_group" "$output_format"
            ;;
        comprehensive)
            show_comprehensive "$account_name" "$resource_group"
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
