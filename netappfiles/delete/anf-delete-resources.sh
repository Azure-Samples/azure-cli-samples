#!/bin/bash
# Azure NetApp Files - Delete Operations
# Safe deletion of ANF resources with validation and backup options

set -e

# Configuration
SCRIPT_NAME="ANF Delete Operations"
LOG_FILE="anf-delete-operations-$(date +%Y%m%d-%H%M%S).log"

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

# Function to confirm deletion
confirm_deletion() {
    local resource_type="$1"
    local resource_name="$2"
    local force_delete="$3"
    
    if [ "$force_delete" = "true" ]; then
        warn "Force delete enabled - skipping confirmation"
        return 0
    fi
    
    warn "This will permanently delete the $resource_type: $resource_name"
    warn "This action cannot be undone!"
    read -p "Are you sure you want to delete this $resource_type? Type 'DELETE' to confirm: " confirmation
    
    if [ "$confirmation" = "DELETE" ]; then
        return 0
    else
        info "Deletion cancelled"
        return 1
    fi
}

# Function to create backup before deletion
create_backup_before_delete() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    
    if [ -z "$volume_name" ]; then
        return 0  # No volume to backup
    fi
    
    info "Creating backup snapshot before deletion..."
    
    local backup_snapshot_name="pre-delete-backup-$(date +%Y%m%d-%H%M%S)"
    
    if az netappfiles snapshot create \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --snapshot-name "$backup_snapshot_name" \
        --resource-group "$resource_group" \
        --location "$(az netappfiles volume show --account-name "$account_name" --pool-name "$pool_name" --volume-name "$volume_name" --resource-group "$resource_group" --query "location" -o tsv)"; then
        log "Backup snapshot created: $backup_snapshot_name"
        echo "$backup_snapshot_name"
    else
        warn "Failed to create backup snapshot"
        return 1
    fi
}

# Function to delete snapshot
delete_snapshot() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local snapshot_name="$4"
    local resource_group="$5"
    local force_delete="$6"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$snapshot_name" ] || [ -z "$resource_group" ]; then
        error "All parameters are required for snapshot deletion"
        return 1
    fi
    
    if ! confirm_deletion "snapshot" "$snapshot_name" "$force_delete"; then
        return 1
    fi
    
    info "Deleting snapshot: $snapshot_name"
    
    az netappfiles snapshot delete \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --snapshot-name "$snapshot_name" \
        --resource-group "$resource_group"
    
    log "Snapshot '$snapshot_name' deleted successfully"
}

# Function to delete volume
delete_volume() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local force_delete="$5"
    local create_backup="$6"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "All parameters are required for volume deletion"
        return 1
    fi
    
    # Check if volume has snapshots
    local snapshot_count=$(az netappfiles snapshot list \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --query "length(@)" --output tsv)
    
    if [ "$snapshot_count" -gt 0 ]; then
        warn "Volume has $snapshot_count snapshots that will also be deleted"
        info "Listing existing snapshots:"
        az netappfiles snapshot list \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --resource-group "$resource_group" \
            --query "[].{Name:name,Created:created}" --output table
    fi
    
    if ! confirm_deletion "volume" "$volume_name" "$force_delete"; then
        return 1
    fi
    
    # Create backup snapshot if requested
    if [ "$create_backup" = "true" ]; then
        backup_snapshot=$(create_backup_before_delete "$account_name" "$pool_name" "$volume_name" "$resource_group")
        if [ $? -eq 0 ] && [ ! -z "$backup_snapshot" ]; then
            info "Backup snapshot created: $backup_snapshot"
        fi
    fi
    
    info "Deleting volume: $volume_name"
    
    # Delete all snapshots first
    if [ "$snapshot_count" -gt 0 ]; then
        info "Deleting $snapshot_count snapshots first..."
        local snapshots=$(az netappfiles snapshot list \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --resource-group "$resource_group" \
            --query "[].name" --output tsv)
        
        for snapshot in $snapshots; do
            if [ "$create_backup" = "true" ] && [ "$snapshot" = "$backup_snapshot" ]; then
                info "Skipping backup snapshot: $snapshot"
                continue
            fi
            info "Deleting snapshot: $snapshot"
            az netappfiles snapshot delete \
                --account-name "$account_name" \
                --pool-name "$pool_name" \
                --volume-name "$volume_name" \
                --snapshot-name "$snapshot" \
                --resource-group "$resource_group"
        done
    fi
    
    # Delete the volume
    az netappfiles volume delete \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group"
    
    log "Volume '$volume_name' deleted successfully"
    
    if [ "$create_backup" = "true" ] && [ ! -z "$backup_snapshot" ]; then
        warn "Backup snapshot '$backup_snapshot' was preserved and needs to be deleted manually if no longer needed"
    fi
}

# Function to delete capacity pool
delete_pool() {
    local account_name="$1"
    local pool_name="$2"
    local resource_group="$3"
    local force_delete="$4"
    local cascade_delete="$5"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, and resource group are required"
        return 1
    fi
    
    # Check if pool has volumes
    local volume_count=$(az netappfiles volume list \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --resource-group "$resource_group" \
        --query "length(@)" --output tsv)
    
    if [ "$volume_count" -gt 0 ]; then
        warn "Pool has $volume_count volumes"
        info "Listing volumes in pool:"
        az netappfiles volume list \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --resource-group "$resource_group" \
            --query "[].{Name:name,Size:usageThreshold,State:provisioningState}" --output table
        
        if [ "$cascade_delete" = "true" ]; then
            warn "Cascade delete enabled - all volumes will be deleted first"
            if ! confirm_deletion "capacity pool and all its volumes" "$pool_name" "$force_delete"; then
                return 1
            fi
            
            # Delete all volumes first
            local volumes=$(az netappfiles volume list \
                --account-name "$account_name" \
                --pool-name "$pool_name" \
                --resource-group "$resource_group" \
                --query "[].name" --output tsv)
            
            for volume in $volumes; do
                info "Deleting volume: $volume"
                delete_volume "$account_name" "$pool_name" "$volume" "$resource_group" "true" "false"
            done
        else
            error "Pool contains volumes. Use --cascade to delete volumes first, or delete volumes manually"
            return 1
        fi
    else
        if ! confirm_deletion "capacity pool" "$pool_name" "$force_delete"; then
            return 1
        fi
    fi
    
    info "Deleting capacity pool: $pool_name"
    
    az netappfiles pool delete \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --resource-group "$resource_group"
    
    log "Capacity pool '$pool_name' deleted successfully"
}

# Function to delete NetApp account
delete_account() {
    local account_name="$1"
    local resource_group="$2"
    local force_delete="$3"
    local cascade_delete="$4"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "Account name and resource group are required"
        return 1
    fi
    
    # Check if account has pools
    local pool_count=$(az netappfiles pool list \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --query "length(@)" --output tsv)
    
    if [ "$pool_count" -gt 0 ]; then
        warn "Account has $pool_count capacity pools"
        info "Listing pools in account:"
        az netappfiles pool list \
            --account-name "$account_name" \
            --resource-group "$resource_group" \
            --query "[].{Name:name,Size:size,ServiceLevel:serviceLevel,State:provisioningState}" --output table
        
        if [ "$cascade_delete" = "true" ]; then
            warn "Cascade delete enabled - all pools and volumes will be deleted first"
            if ! confirm_deletion "NetApp account and all its resources" "$account_name" "$force_delete"; then
                return 1
            fi
            
            # Delete all pools first
            local pools=$(az netappfiles pool list \
                --account-name "$account_name" \
                --resource-group "$resource_group" \
                --query "[].name" --output tsv)
            
            for pool in $pools; do
                info "Deleting pool: $pool"
                delete_pool "$account_name" "$pool" "$resource_group" "true" "true"
            done
        else
            error "Account contains pools. Use --cascade to delete pools first, or delete pools manually"
            return 1
        fi
    else
        if ! confirm_deletion "NetApp account" "$account_name" "$force_delete"; then
            return 1
        fi
    fi
    
    info "Deleting NetApp account: $account_name"
    
    az netappfiles account delete \
        --account-name "$account_name" \
        --resource-group "$resource_group"
    
    log "NetApp account '$account_name' deleted successfully"
}

# Function to delete snapshot policy
delete_snapshot_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local force_delete="$4"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ]; then
        error "Account name, policy name, and resource group are required"
        return 1
    fi
    
    if ! confirm_deletion "snapshot policy" "$policy_name" "$force_delete"; then
        return 1
    fi
    
    info "Deleting snapshot policy: $policy_name"
    
    az netappfiles snapshot policy delete \
        --account-name "$account_name" \
        --snapshot-policy-name "$policy_name" \
        --resource-group "$resource_group"
    
    log "Snapshot policy '$policy_name' deleted successfully"
}

# Function to delete backup policy
delete_backup_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local force_delete="$4"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ]; then
        error "Account name, policy name, and resource group are required"
        return 1
    fi
    
    if ! confirm_deletion "backup policy" "$policy_name" "$force_delete"; then
        return 1
    fi
    
    info "Deleting backup policy: $policy_name"
    
    az netappfiles backup policy delete \
        --account-name "$account_name" \
        --backup-policy-name "$policy_name" \
        --resource-group "$resource_group"
    
    log "Backup policy '$policy_name' deleted successfully"
}

# Function to bulk delete old snapshots
delete_old_snapshots() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local days_old="$5"
    local force_delete="$6"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ] || [ -z "$days_old" ]; then
        error "All parameters are required for old snapshot deletion"
        return 1
    fi
    
    local cutoff_date=$(date -d "$days_old days ago" +%Y-%m-%d)
    info "Deleting snapshots older than $days_old days (before $cutoff_date)"
    
    # Get old snapshots
    local old_snapshots=$(az netappfiles snapshot list \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --query "[?created<'$cutoff_date'].name" --output tsv)
    
    if [ -z "$old_snapshots" ]; then
        info "No snapshots older than $days_old days found"
        return 0
    fi
    
    local snapshot_count=$(echo "$old_snapshots" | wc -w)
    warn "Found $snapshot_count snapshots older than $days_old days"
    
    if ! confirm_deletion "$snapshot_count old snapshots" "older than $days_old days" "$force_delete"; then
        return 1
    fi
    
    for snapshot in $old_snapshots; do
        info "Deleting old snapshot: $snapshot"
        az netappfiles snapshot delete \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --snapshot-name "$snapshot" \
            --resource-group "$resource_group"
    done
    
    log "Deleted $snapshot_count old snapshots successfully"
}

# Function to cleanup empty resources
cleanup_empty_resources() {
    local resource_group="$1"
    local force_delete="$2"
    
    if [ -z "$resource_group" ]; then
        error "Resource group is required"
        return 1
    fi
    
    log "Cleaning up empty ANF resources in resource group: $resource_group"
    
    # Find empty pools (no volumes)
    info "Finding empty capacity pools..."
    local empty_pools=$(az netappfiles pool list \
        --query "[?resourceGroup=='$resource_group'].[accountName,name]" \
        --output tsv | while read account pool; do
            volume_count=$(az netappfiles volume list \
                --account-name "$account" \
                --pool-name "$pool" \
                --resource-group "$resource_group" \
                --query "length(@)" --output tsv)
            if [ "$volume_count" -eq 0 ]; then
                echo "$account:$pool"
            fi
        done)
    
    if [ ! -z "$empty_pools" ]; then
        info "Empty pools found:"
        echo "$empty_pools"
        
        if confirm_deletion "empty capacity pools" "$(echo "$empty_pools" | wc -l)" "$force_delete"; then
            echo "$empty_pools" | while IFS=':' read account pool; do
                info "Deleting empty pool: $pool"
                delete_pool "$account" "$pool" "$resource_group" "true" "false"
            done
        fi
    fi
    
    # Find empty accounts (no pools)
    info "Finding empty NetApp accounts..."
    local empty_accounts=$(az netappfiles account list \
        --resource-group "$resource_group" \
        --query "[].name" --output tsv | while read account; do
            pool_count=$(az netappfiles pool list \
                --account-name "$account" \
                --resource-group "$resource_group" \
                --query "length(@)" --output tsv)
            if [ "$pool_count" -eq 0 ]; then
                echo "$account"
            fi
        done)
    
    if [ ! -z "$empty_accounts" ]; then
        info "Empty accounts found:"
        echo "$empty_accounts"
        
        if confirm_deletion "empty NetApp accounts" "$(echo "$empty_accounts" | wc -l)" "$force_delete"; then
            echo "$empty_accounts" | while read account; do
                info "Deleting empty account: $account"
                delete_account "$account" "$resource_group" "true" "false"
            done
        fi
    fi
    
    log "Cleanup completed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  snapshot --account ACCOUNT --pool POOL --volume VOLUME --snapshot SNAPSHOT --rg RG"
    echo "  volume --account ACCOUNT --pool POOL --volume VOLUME --rg RG [--backup]"
    echo "  pool --account ACCOUNT --pool POOL --rg RG [--cascade]"
    echo "  account --account ACCOUNT --rg RG [--cascade]"
    echo "  snapshot-policy --account ACCOUNT --policy POLICY --rg RG"
    echo "  backup-policy --account ACCOUNT --policy POLICY --rg RG"
    echo "  old-snapshots --account ACCOUNT --pool POOL --volume VOLUME --rg RG --days DAYS"
    echo "  cleanup --rg RG"
    echo ""
    echo "Options:"
    echo "  --account ACCOUNT              NetApp account name"
    echo "  --pool POOL                    Capacity pool name"
    echo "  --volume VOLUME                Volume name"
    echo "  --snapshot SNAPSHOT            Snapshot name"
    echo "  --policy POLICY                Policy name"
    echo "  --rg, --resource-group RG      Resource group"
    echo "  --days DAYS                    Number of days for old snapshot deletion"
    echo "  --cascade                      Delete child resources first"
    echo "  --backup                       Create backup snapshot before deletion"
    echo "  --force                        Skip confirmation prompts"
    echo ""
    echo "Examples:"
    echo "  $0 volume --account myAccount --pool myPool --volume myVolume --rg myRG --backup"
    echo "  $0 pool --account myAccount --pool myPool --rg myRG --cascade"
    echo "  $0 old-snapshots --account myAccount --pool myPool --volume myVolume --rg myRG --days 30"
    echo "  $0 cleanup --rg myRG"
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
    local snapshot_name=""
    local policy_name=""
    local resource_group=""
    local days_old=""
    local force_delete="false"
    local cascade_delete="false"
    local create_backup="false"
    
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
            --snapshot)
                snapshot_name="$2"
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
            --days)
                days_old="$2"
                shift 2
                ;;
            --force)
                force_delete="true"
                shift
                ;;
            --cascade)
                cascade_delete="true"
                shift
                ;;
            --backup)
                create_backup="true"
                shift
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
        snapshot)
            delete_snapshot "$account_name" "$pool_name" "$volume_name" "$snapshot_name" "$resource_group" "$force_delete"
            ;;
        volume)
            delete_volume "$account_name" "$pool_name" "$volume_name" "$resource_group" "$force_delete" "$create_backup"
            ;;
        pool)
            delete_pool "$account_name" "$pool_name" "$resource_group" "$force_delete" "$cascade_delete"
            ;;
        account)
            delete_account "$account_name" "$resource_group" "$force_delete" "$cascade_delete"
            ;;
        snapshot-policy)
            delete_snapshot_policy "$account_name" "$policy_name" "$resource_group" "$force_delete"
            ;;
        backup-policy)
            delete_backup_policy "$account_name" "$policy_name" "$resource_group" "$force_delete"
            ;;
        old-snapshots)
            delete_old_snapshots "$account_name" "$pool_name" "$volume_name" "$resource_group" "$days_old" "$force_delete"
            ;;
        cleanup)
            cleanup_empty_resources "$resource_group" "$force_delete"
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
