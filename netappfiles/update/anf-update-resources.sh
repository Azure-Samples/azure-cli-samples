#!/bin/bash
# Azure NetApp Files - Update Operations
# Update/modify existing ANF resources with comprehensive options

set -e

# Configuration
SCRIPT_NAME="ANF Update Operations"
LOG_FILE="anf-update-operations-$(date +%Y%m%d-%H%M%S).log"

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

# Function to update NetApp account
update_account() {
    local account_name="$1"
    local resource_group="$2"
    local tags="$3"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "Account name and resource group are required"
        return 1
    fi
    
    info "Updating NetApp account: $account_name"
    
    local update_cmd="az netappfiles account update --account-name \"$account_name\" --resource-group \"$resource_group\""
    
    if [ ! -z "$tags" ]; then
        update_cmd="$update_cmd --tags $tags"
        log "Adding tags: $tags"
    fi
    
    eval "$update_cmd"
    log "NetApp account '$account_name' updated successfully"
}

# Function to update capacity pool
update_pool() {
    local account_name="$1"
    local pool_name="$2"
    local resource_group="$3"
    local size="$4"
    local qos_type="$5"
    local tags="$6"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, and resource group are required"
        return 1
    fi
    
    info "Updating capacity pool: $pool_name"
    
    local update_cmd="az netappfiles pool update --account-name \"$account_name\" --pool-name \"$pool_name\" --resource-group \"$resource_group\""
    
    if [ ! -z "$size" ]; then
        update_cmd="$update_cmd --size $size"
        log "Updating size to: $size bytes"
    fi
    
    if [ ! -z "$qos_type" ]; then
        update_cmd="$update_cmd --qos-type $qos_type"
        log "Updating QoS type to: $qos_type"
    fi
    
    if [ ! -z "$tags" ]; then
        update_cmd="$update_cmd --tags $tags"
        log "Adding tags: $tags"
    fi
    
    eval "$update_cmd"
    log "Capacity pool '$pool_name' updated successfully"
}

# Function to update volume
update_volume() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local size="$5"
    local service_level="$6"
    local throughput="$7"
    local unix_permissions="$8"
    local tags="$9"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Updating volume: $volume_name"
    
    local update_cmd="az netappfiles volume update --account-name \"$account_name\" --pool-name \"$pool_name\" --volume-name \"$volume_name\" --resource-group \"$resource_group\""
    
    if [ ! -z "$size" ]; then
        update_cmd="$update_cmd --usage-threshold $size"
        log "Updating size to: $size bytes"
    fi
    
    if [ ! -z "$service_level" ]; then
        update_cmd="$update_cmd --service-level $service_level"
        log "Updating service level to: $service_level"
    fi
    
    if [ ! -z "$throughput" ]; then
        update_cmd="$update_cmd --throughput-mibps $throughput"
        log "Updating throughput to: $throughput MiB/s"
    fi
    
    if [ ! -z "$unix_permissions" ]; then
        update_cmd="$update_cmd --unix-permissions $unix_permissions"
        log "Updating UNIX permissions to: $unix_permissions"
    fi
    
    if [ ! -z "$tags" ]; then
        update_cmd="$update_cmd --tags $tags"
        log "Adding tags: $tags"
    fi
    
    eval "$update_cmd"
    log "Volume '$volume_name' updated successfully"
}

# Function to update export policy
update_export_policy() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local export_policy_file="$5"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Updating export policy for volume: $volume_name"
    
    if [ ! -z "$export_policy_file" ] && [ -f "$export_policy_file" ]; then
        az netappfiles volume update \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --resource-group "$resource_group" \
            --export-policy @"$export_policy_file"
        log "Export policy updated from file: $export_policy_file"
    else
        # Create a default export policy
        local default_policy='{"rules":[{"ruleIndex":1,"allowedClients":"0.0.0.0/0","cifs":false,"nfsv3":true,"nfsv41":false,"unixReadOnly":false,"unixReadWrite":true}]}'
        echo "$default_policy" > /tmp/export-policy.json
        
        az netappfiles volume update \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --resource-group "$resource_group" \
            --export-policy @/tmp/export-policy.json
        
        rm /tmp/export-policy.json
        log "Default export policy applied"
    fi
}

# Function to update snapshot policy
update_snapshot_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local enabled="$4"
    local hourly_snapshots="$5"
    local daily_snapshots="$6"
    local weekly_snapshots="$7"
    local monthly_snapshots="$8"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ]; then
        error "Account name, policy name, and resource group are required"
        return 1
    fi
    
    info "Updating snapshot policy: $policy_name"
    
    local update_cmd="az netappfiles snapshot policy update --account-name \"$account_name\" --snapshot-policy-name \"$policy_name\" --resource-group \"$resource_group\""
    
    if [ ! -z "$enabled" ]; then
        update_cmd="$update_cmd --enabled $enabled"
        log "Setting enabled to: $enabled"
    fi
    
    if [ ! -z "$hourly_snapshots" ]; then
        update_cmd="$update_cmd --hourly-snapshots $hourly_snapshots --hourly-minute 0"
        log "Setting hourly snapshots to: $hourly_snapshots"
    fi
    
    if [ ! -z "$daily_snapshots" ]; then
        update_cmd="$update_cmd --daily-snapshots $daily_snapshots --daily-hour 0 --daily-minute 0"
        log "Setting daily snapshots to: $daily_snapshots"
    fi
    
    if [ ! -z "$weekly_snapshots" ]; then
        update_cmd="$update_cmd --weekly-snapshots $weekly_snapshots --weekly-day Sunday --weekly-hour 0 --weekly-minute 0"
        log "Setting weekly snapshots to: $weekly_snapshots"
    fi
    
    if [ ! -z "$monthly_snapshots" ]; then
        update_cmd="$update_cmd --monthly-snapshots $monthly_snapshots --monthly-days-of-month 1 --monthly-hour 0 --monthly-minute 0"
        log "Setting monthly snapshots to: $monthly_snapshots"
    fi
    
    eval "$update_cmd"
    log "Snapshot policy '$policy_name' updated successfully"
}

# Function to update backup policy
update_backup_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local enabled="$4"
    local daily_backups="$5"
    local weekly_backups="$6"
    local monthly_backups="$7"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ]; then
        error "Account name, policy name, and resource group are required"
        return 1
    fi
    
    info "Updating backup policy: $policy_name"
    
    local update_cmd="az netappfiles backup policy update --account-name \"$account_name\" --backup-policy-name \"$policy_name\" --resource-group \"$resource_group\""
    
    if [ ! -z "$enabled" ]; then
        update_cmd="$update_cmd --enabled $enabled"
        log "Setting enabled to: $enabled"
    fi
    
    if [ ! -z "$daily_backups" ]; then
        update_cmd="$update_cmd --daily-backups-to-keep $daily_backups"
        log "Setting daily backups to keep: $daily_backups"
    fi
    
    if [ ! -z "$weekly_backups" ]; then
        update_cmd="$update_cmd --weekly-backups-to-keep $weekly_backups"
        log "Setting weekly backups to keep: $weekly_backups"
    fi
    
    if [ ! -z "$monthly_backups" ]; then
        update_cmd="$update_cmd --monthly-backups-to-keep $monthly_backups"
        log "Setting monthly backups to keep: $monthly_backups"
    fi
    
    eval "$update_cmd"
    log "Backup policy '$policy_name' updated successfully"
}

# Function to resize volume (common operation)
resize_volume() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local new_size="$5"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ] || [ -z "$new_size" ]; then
        error "All parameters are required for volume resize"
        return 1
    fi
    
    # Get current size for comparison
    local current_size=$(az netappfiles volume show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --query "usageThreshold" \
        --output tsv)
    
    info "Resizing volume '$volume_name' from $current_size bytes to $new_size bytes"
    
    # Validate that new size is larger (ANF doesn't support shrinking)
    if [ "$new_size" -le "$current_size" ]; then
        error "New size ($new_size) must be larger than current size ($current_size)"
        return 1
    fi
    
    az netappfiles volume update \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --usage-threshold "$new_size"
    
    log "Volume '$volume_name' resized successfully to $new_size bytes"
}

# Function to change volume service level
change_volume_service_level() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local new_service_level="$5"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ] || [ -z "$new_service_level" ]; then
        error "All parameters are required for service level change"
        return 1
    fi
    
    info "Changing service level for volume '$volume_name' to $new_service_level"
    
    # Note: Service level change requires moving volume to a different pool with the target service level
    warn "Service level change requires moving volume to a pool with the target service level"
    warn "This operation may cause temporary disruption"
    
    read -p "Continue with service level change? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        az netappfiles volume pool-change \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --resource-group "$resource_group" \
            --new-pool-resource-id "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resource_group/providers/Microsoft.NetApp/netAppAccounts/$account_name/capacityPools/$pool_name"
        
        log "Service level change initiated for volume '$volume_name'"
    else
        info "Service level change cancelled"
    fi
}

# Function to update tags on multiple resources
bulk_update_tags() {
    local resource_group="$1"
    local tags="$2"
    
    if [ -z "$resource_group" ] || [ -z "$tags" ]; then
        error "Resource group and tags are required"
        return 1
    fi
    
    log "Bulk updating tags for all ANF resources in resource group: $resource_group"
    
    # Update NetApp accounts
    local accounts=$(az netappfiles account list --resource-group "$resource_group" --query "[].name" --output tsv)
    for account in $accounts; do
        info "Updating tags for account: $account"
        az netappfiles account update --account-name "$account" --resource-group "$resource_group" --tags $tags
    done
    
    # Update capacity pools
    local pools=$(az netappfiles pool list --query "[?resourceGroup=='$resource_group'].{account:accountName,pool:name}" --output tsv)
    while IFS=$'\t' read -r account_name pool_name; do
        if [ ! -z "$account_name" ] && [ ! -z "$pool_name" ]; then
            info "Updating tags for pool: $pool_name in account: $account_name"
            az netappfiles pool update --account-name "$account_name" --pool-name "$pool_name" --resource-group "$resource_group" --tags $tags
        fi
    done <<< "$pools"
    
    # Update volumes
    local volumes=$(az netappfiles volume list --query "[?resourceGroup=='$resource_group'].{account:accountName,pool:poolName,volume:name}" --output tsv)
    while IFS=$'\t' read -r account_name pool_name volume_name; do
        if [ ! -z "$account_name" ] && [ ! -z "$pool_name" ] && [ ! -z "$volume_name" ]; then
            info "Updating tags for volume: $volume_name"
            az netappfiles volume update --account-name "$account_name" --pool-name "$pool_name" --volume-name "$volume_name" --resource-group "$resource_group" --tags $tags
        fi
    done <<< "$volumes"
    
    log "Bulk tag update completed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  account --account ACCOUNT --rg RG [--tags TAGS]"
    echo "  pool --account ACCOUNT --pool POOL --rg RG [--size SIZE] [--qos-type QOS] [--tags TAGS]"
    echo "  volume --account ACCOUNT --pool POOL --volume VOLUME --rg RG [options]"
    echo "  export-policy --account ACCOUNT --pool POOL --volume VOLUME --rg RG [--policy-file FILE]"
    echo "  snapshot-policy --account ACCOUNT --policy POLICY --rg RG [options]"
    echo "  backup-policy --account ACCOUNT --policy POLICY --rg RG [options]"
    echo "  resize-volume --account ACCOUNT --pool POOL --volume VOLUME --rg RG --size SIZE"
    echo "  change-service-level --account ACCOUNT --pool POOL --volume VOLUME --rg RG --service-level LEVEL"
    echo "  bulk-tags --rg RG --tags TAGS"
    echo ""
    echo "Volume Update Options:"
    echo "  --size SIZE                     New size in bytes"
    echo "  --service-level LEVEL          Service level (Standard, Premium, Ultra)"
    echo "  --throughput THROUGHPUT        Throughput in MiB/s"
    echo "  --unix-permissions PERMS       UNIX permissions (e.g., 0755)"
    echo "  --tags TAGS                    Tags in key=value format"
    echo ""
    echo "Snapshot Policy Options:"
    echo "  --enabled true/false           Enable/disable policy"
    echo "  --hourly NUM                   Number of hourly snapshots to keep"
    echo "  --daily NUM                    Number of daily snapshots to keep"
    echo "  --weekly NUM                   Number of weekly snapshots to keep"
    echo "  --monthly NUM                  Number of monthly snapshots to keep"
    echo ""
    echo "Examples:"
    echo "  $0 volume --account myAccount --pool myPool --volume myVolume --rg myRG --size 214748364800"
    echo "  $0 resize-volume --account myAccount --pool myPool --volume myVolume --rg myRG --size 429496729600"
    echo "  $0 snapshot-policy --account myAccount --policy myPolicy --rg myRG --daily 7 --weekly 4"
    echo "  $0 bulk-tags --rg myRG --tags Environment=Production Department=IT"
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
    local account_name=""
    local pool_name=""
    local volume_name=""
    local policy_name=""
    local resource_group=""
    local size=""
    local service_level=""
    local throughput=""
    local unix_permissions=""
    local qos_type=""
    local tags=""
    local enabled=""
    local hourly_snapshots=""
    local daily_snapshots=""
    local weekly_snapshots=""
    local monthly_snapshots=""
    local daily_backups=""
    local weekly_backups=""
    local monthly_backups=""
    local export_policy_file=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
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
            --policy)
                policy_name="$2"
                shift 2
                ;;
            --rg|--resource-group)
                resource_group="$2"
                shift 2
                ;;
            --size)
                size="$2"
                shift 2
                ;;
            --service-level)
                service_level="$2"
                shift 2
                ;;
            --throughput)
                throughput="$2"
                shift 2
                ;;
            --unix-permissions)
                unix_permissions="$2"
                shift 2
                ;;
            --qos-type)
                qos_type="$2"
                shift 2
                ;;
            --tags)
                tags="$2"
                shift 2
                ;;
            --enabled)
                enabled="$2"
                shift 2
                ;;
            --hourly)
                hourly_snapshots="$2"
                shift 2
                ;;
            --daily)
                daily_snapshots="$2"
                shift 2
                ;;
            --weekly)
                weekly_snapshots="$2"
                shift 2
                ;;
            --monthly)
                monthly_snapshots="$2"
                shift 2
                ;;
            --daily-backups)
                daily_backups="$2"
                shift 2
                ;;
            --weekly-backups)
                weekly_backups="$2"
                shift 2
                ;;
            --monthly-backups)
                monthly_backups="$2"
                shift 2
                ;;
            --policy-file)
                export_policy_file="$2"
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
            update_account "$account_name" "$resource_group" "$tags"
            ;;
        pool)
            update_pool "$account_name" "$pool_name" "$resource_group" "$size" "$qos_type" "$tags"
            ;;
        volume)
            update_volume "$account_name" "$pool_name" "$volume_name" "$resource_group" "$size" "$service_level" "$throughput" "$unix_permissions" "$tags"
            ;;
        export-policy)
            update_export_policy "$account_name" "$pool_name" "$volume_name" "$resource_group" "$export_policy_file"
            ;;
        snapshot-policy)
            update_snapshot_policy "$account_name" "$policy_name" "$resource_group" "$enabled" "$hourly_snapshots" "$daily_snapshots" "$weekly_snapshots" "$monthly_snapshots"
            ;;
        backup-policy)
            update_backup_policy "$account_name" "$policy_name" "$resource_group" "$enabled" "$daily_backups" "$weekly_backups" "$monthly_backups"
            ;;
        resize-volume)
            resize_volume "$account_name" "$pool_name" "$volume_name" "$resource_group" "$size"
            ;;
        change-service-level)
            change_volume_service_level "$account_name" "$pool_name" "$volume_name" "$resource_group" "$service_level"
            ;;
        bulk-tags)
            bulk_update_tags "$resource_group" "$tags"
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
