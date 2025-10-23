#!/bin/bash
# Azure NetApp Files - Backup Policy Management
# Create, configure, and manage backup policies for ANF resources

set -e

# Configuration
SCRIPT_NAME="ANF Backup Policy Management"
LOG_FILE="anf-backup-policies-$(date +%Y%m%d-%H%M%S).log"

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

# Function to create a comprehensive backup policy
create_backup_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local location="$4"
    local daily_backups="${5:-7}"
    local weekly_backups="${6:-4}"
    local monthly_backups="${7:-12}"
    local enabled="${8:-true}"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Account name, policy name, resource group, and location are required"
        return 1
    fi
    
    info "Creating backup policy: $policy_name"
    
    # Build the command with comprehensive parameters
    local cmd="az netappfiles account backup-policy create"
    cmd+=" --account-name '$account_name'"
    cmd+=" --backup-policy-name '$policy_name'"
    cmd+=" --resource-group '$resource_group'"
    cmd+=" --location '$location'"
    cmd+=" --enabled $enabled"
    
    # Add backup retention settings
    if [ "$daily_backups" -gt 0 ]; then
        cmd+=" --daily-backups-to-keep $daily_backups"
    fi
    
    if [ "$weekly_backups" -gt 0 ]; then
        cmd+=" --weekly-backups-to-keep $weekly_backups"
    fi
    
    if [ "$monthly_backups" -gt 0 ]; then
        cmd+=" --monthly-backups-to-keep $monthly_backups"
    fi
    
    log "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        log "Backup policy '$policy_name' created successfully"
        
        # Show the created policy
        show_backup_policy "$account_name" "$policy_name" "$resource_group"
    else
        error "Failed to create backup policy '$policy_name'"
        return 1
    fi
}

# Function to create enterprise backup policy with advanced settings
create_enterprise_backup_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local location="$4"
    
    info "Creating enterprise-grade backup policy: $policy_name"
    
    # Enterprise backup settings: 30 daily, 12 weekly, 60 monthly
    az netappfiles account backup-policy create \
        --account-name "$account_name" \
        --backup-policy-name "$policy_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --enabled true \
        --daily-backups-to-keep 30 \
        --weekly-backups-to-keep 12 \
        --monthly-backups-to-keep 60 \
        --tags Environment=Production BackupTier=Enterprise
    
    log "Enterprise backup policy '$policy_name' created with extended retention"
}

# Function to create development backup policy
create_dev_backup_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local location="$4"
    
    info "Creating development backup policy: $policy_name"
    
    # Development backup settings: 3 daily, 2 weekly, 1 monthly
    az netappfiles account backup-policy create \
        --account-name "$account_name" \
        --backup-policy-name "$policy_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --enabled true \
        --daily-backups-to-keep 3 \
        --weekly-backups-to-keep 2 \
        --monthly-backups-to-keep 1 \
        --tags Environment=Development BackupTier=Basic
    
    log "Development backup policy '$policy_name' created with minimal retention"
}

# Function to update backup policy
update_backup_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local daily_backups="$4"
    local weekly_backups="$5"
    local monthly_backups="$6"
    local enabled="$7"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ]; then
        error "Account name, policy name, and resource group are required"
        return 1
    fi
    
    info "Updating backup policy: $policy_name"
    
    # Build update command
    local cmd="az netappfiles account backup-policy update"
    cmd+=" --account-name '$account_name'"
    cmd+=" --backup-policy-name '$policy_name'"
    cmd+=" --resource-group '$resource_group'"
    
    [ -n "$enabled" ] && cmd+=" --enabled $enabled"
    [ -n "$daily_backups" ] && cmd+=" --daily-backups-to-keep $daily_backups"
    [ -n "$weekly_backups" ] && cmd+=" --weekly-backups-to-keep $weekly_backups"
    [ -n "$monthly_backups" ] && cmd+=" --monthly-backups-to-keep $monthly_backups"
    
    log "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        log "Backup policy '$policy_name' updated successfully"
    else
        error "Failed to update backup policy '$policy_name'"
        return 1
    fi
}

# Function to show backup policy details
show_backup_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local output_format="${4:-table}"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ]; then
        error "Account name, policy name, and resource group are required"
        return 1
    fi
    
    info "Getting backup policy details: $policy_name"
    
    az netappfiles account backup-policy show \
        --account-name "$account_name" \
        --backup-policy-name "$policy_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to list all backup policies
list_backup_policies() {
    local account_name="$1"
    local resource_group="$2"
    local output_format="${3:-table}"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "Account name and resource group are required"
        return 1
    fi
    
    info "Listing backup policies for account: $account_name"
    
    az netappfiles account backup-policy list \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to delete backup policy
delete_backup_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    local force="${4:-false}"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ]; then
        error "Account name, policy name, and resource group are required"
        return 1
    fi
    
    if [ "$force" != "true" ]; then
        read -p "Are you sure you want to delete backup policy '$policy_name'? (y/N): " confirmation
        if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
            warn "Backup policy deletion cancelled"
            return 0
        fi
    fi
    
    info "Deleting backup policy: $policy_name"
    
    az netappfiles account backup-policy delete \
        --account-name "$account_name" \
        --backup-policy-name "$policy_name" \
        --resource-group "$resource_group" \
        --yes
    
    if [ $? -eq 0 ]; then
        log "Backup policy '$policy_name' deleted successfully"
    else
        error "Failed to delete backup policy '$policy_name'"
        return 1
    fi
}

# Function to create backup vault
create_backup_vault() {
    local account_name="$1"
    local vault_name="$2"
    local resource_group="$3"
    local location="$4"
    
    if [ -z "$account_name" ] || [ -z "$vault_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Account name, vault name, resource group, and location are required"
        return 1
    fi
    
    info "Creating backup vault: $vault_name"
    
    az netappfiles account backup-vault create \
        --account-name "$account_name" \
        --vault-name "$vault_name" \
        --resource-group "$resource_group" \
        --location "$location"
    
    if [ $? -eq 0 ]; then
        log "Backup vault '$vault_name' created successfully"
    else
        error "Failed to create backup vault '$vault_name'"
        return 1
    fi
}

# Function to create manual backup
create_manual_backup() {
    local account_name="$1"
    local vault_name="$2"
    local backup_name="$3"
    local volume_resource_id="$4"
    local resource_group="$5"
    
    if [ -z "$account_name" ] || [ -z "$vault_name" ] || [ -z "$backup_name" ] || [ -z "$volume_resource_id" ] || [ -z "$resource_group" ]; then
        error "All parameters are required for manual backup creation"
        return 1
    fi
    
    info "Creating manual backup: $backup_name"
    
    az netappfiles account backup-vault backup create \
        --account-name "$account_name" \
        --vault-name "$vault_name" \
        --backup-name "$backup_name" \
        --resource-group "$resource_group" \
        --volume-resource-id "$volume_resource_id" \
        --use-existing-snapshot false
    
    if [ $? -eq 0 ]; then
        log "Manual backup '$backup_name' created successfully"
    else
        error "Failed to create manual backup '$backup_name'"
        return 1
    fi
}

# Function to migrate backups to vault
migrate_backups_to_vault() {
    local account_name="$1"
    local vault_name="$2"
    local resource_group="$3"
    
    if [ -z "$account_name" ] || [ -z "$vault_name" ] || [ -z "$resource_group" ]; then
        error "Account name, vault name, and resource group are required"
        return 1
    fi
    
    info "Migrating backups to vault: $vault_name"
    
    az netappfiles account migrate-backup \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --backup-vault-id "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resource_group/providers/Microsoft.NetApp/netAppAccounts/$account_name/backupVaults/$vault_name"
    
    if [ $? -eq 0 ]; then
        log "Backup migration to vault '$vault_name' completed successfully"
    else
        error "Failed to migrate backups to vault '$vault_name'"
        return 1
    fi
}

# Function to create comprehensive backup strategy
create_backup_strategy() {
    local account_name="$1"
    local resource_group="$2"
    local location="$3"
    local environment="${4:-production}"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Account name, resource group, and location are required"
        return 1
    fi
    
    log "Creating comprehensive backup strategy for environment: $environment"
    
    case "$environment" in
        "production"|"prod")
            # Create enterprise backup vault
            create_backup_vault "$account_name" "${account_name}-prod-vault" "$resource_group" "$location"
            
            # Create enterprise backup policy
            create_enterprise_backup_policy "$account_name" "${account_name}-prod-policy" "$resource_group" "$location"
            
            # Create critical data policy (extended retention)
            create_backup_policy "$account_name" "${account_name}-critical-policy" "$resource_group" "$location" 60 24 120 true
            ;;
        "development"|"dev")
            # Create development backup vault
            create_backup_vault "$account_name" "${account_name}-dev-vault" "$resource_group" "$location"
            
            # Create development backup policy
            create_dev_backup_policy "$account_name" "${account_name}-dev-policy" "$resource_group" "$location"
            ;;
        "testing"|"test")
            # Create testing backup vault
            create_backup_vault "$account_name" "${account_name}-test-vault" "$resource_group" "$location"
            
            # Create testing backup policy (minimal retention)
            create_backup_policy "$account_name" "${account_name}-test-policy" "$resource_group" "$location" 1 1 0 true
            ;;
        *)
            warn "Unknown environment: $environment. Creating standard backup strategy."
            create_backup_vault "$account_name" "${account_name}-vault" "$resource_group" "$location"
            create_backup_policy "$account_name" "${account_name}-policy" "$resource_group" "$location" 7 4 12 true
            ;;
    esac
    
    log "Backup strategy creation completed for environment: $environment"
}

# Function to show comprehensive backup status
show_backup_status() {
    local account_name="$1"
    local resource_group="$2"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "Account name and resource group are required"
        return 1
    fi
    
    log "Generating comprehensive backup status for account: $account_name"
    
    echo -e "\n${BLUE}=== Backup Policies ===${NC}"
    list_backup_policies "$account_name" "$resource_group" "table"
    
    echo -e "\n${BLUE}=== Backup Vaults ===${NC}"
    az netappfiles account backup-vault list \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --query "[].{Name:name,State:provisioningState,CreationTime:creationTime}" \
        --output table
    
    echo -e "\n${BLUE}=== Recent Backups ===${NC}"
    local vaults=$(az netappfiles account backup-vault list \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --query "[].name" -o tsv)
    
    for vault in $vaults; do
        echo -e "\n${YELLOW}Vault: $vault${NC}"
        az netappfiles account backup-vault backup list \
            --account-name "$account_name" \
            --vault-name "$vault" \
            --resource-group "$resource_group" \
            --query "[].{Backup:name,Status:backupState,Created:creationDate,Size:size}" \
            --output table 2>/dev/null || echo "No backups found in vault: $vault"
    done
}

# Function to validate backup policy configuration
validate_backup_policy() {
    local account_name="$1"
    local policy_name="$2"
    local resource_group="$3"
    
    if [ -z "$account_name" ] || [ -z "$policy_name" ] || [ -z "$resource_group" ]; then
        error "Account name, policy name, and resource group are required"
        return 1
    fi
    
    info "Validating backup policy configuration: $policy_name"
    
    local policy_data=$(az netappfiles account backup-policy show \
        --account-name "$account_name" \
        --backup-policy-name "$policy_name" \
        --resource-group "$resource_group" \
        --output json 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$policy_data" ]; then
        error "Backup policy '$policy_name' not found or inaccessible"
        return 1
    fi
    
    local enabled=$(echo "$policy_data" | jq -r '.enabled // false')
    local daily=$(echo "$policy_data" | jq -r '.dailyBackupsToKeep // 0')
    local weekly=$(echo "$policy_data" | jq -r '.weeklyBackupsToKeep // 0')
    local monthly=$(echo "$policy_data" | jq -r '.monthlyBackupsToKeep // 0')
    
    echo -e "\n${BLUE}=== Backup Policy Validation ===${NC}"
    echo "Policy Name: $policy_name"
    echo "Enabled: $enabled"
    echo "Daily Backups: $daily"
    echo "Weekly Backups: $weekly"
    echo "Monthly Backups: $monthly"
    
    # Validation checks
    local validation_passed=true
    
    if [ "$enabled" != "true" ]; then
        warn "Policy is disabled - backups will not be created"
        validation_passed=false
    fi
    
    if [ "$daily" -eq 0 ] && [ "$weekly" -eq 0 ] && [ "$monthly" -eq 0 ]; then
        error "No backup retention configured - backups will be deleted immediately"
        validation_passed=false
    fi
    
    if [ "$validation_passed" = true ]; then
        log "Backup policy validation passed"
    else
        error "Backup policy validation failed - please review configuration"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create --account ACCOUNT --name NAME --rg RG --location LOCATION [options]"
    echo "  create-enterprise --account ACCOUNT --name NAME --rg RG --location LOCATION"
    echo "  create-dev --account ACCOUNT --name NAME --rg RG --location LOCATION"
    echo "  update --account ACCOUNT --name NAME --rg RG [options]"
    echo "  delete --account ACCOUNT --name NAME --rg RG [--force]"
    echo "  show --account ACCOUNT --name NAME --rg RG [--format FORMAT]"
    echo "  list --account ACCOUNT --rg RG [--format FORMAT]"
    echo "  create-vault --account ACCOUNT --name NAME --rg RG --location LOCATION"
    echo "  create-backup --account ACCOUNT --vault VAULT --name NAME --volume-id ID --rg RG"
    echo "  migrate-backups --account ACCOUNT --vault VAULT --rg RG"
    echo "  strategy --account ACCOUNT --rg RG --location LOCATION --env ENVIRONMENT"
    echo "  status --account ACCOUNT --rg RG"
    echo "  validate --account ACCOUNT --name NAME --rg RG"
    echo ""
    echo "Options:"
    echo "  --account ACCOUNT              NetApp account name"
    echo "  --name NAME                    Policy/vault/backup name"
    echo "  --rg, --resource-group RG      Resource group"
    echo "  --location LOCATION            Azure location"
    echo "  --daily DAYS                   Daily backups to keep"
    echo "  --weekly WEEKS                 Weekly backups to keep"
    echo "  --monthly MONTHS               Monthly backups to keep"
    echo "  --enabled true/false           Enable/disable policy"
    echo "  --vault VAULT                  Backup vault name"
    echo "  --volume-id ID                 Volume resource ID"
    echo "  --env ENVIRONMENT              Environment (production/development/testing)"
    echo "  --force                        Force deletion without confirmation"
    echo "  --format FORMAT                Output format (table, json, yaml, tsv)"
    echo ""
    echo "Examples:"
    echo "  $0 create --account myAccount --name myPolicy --rg myRG --location eastus"
    echo "  $0 strategy --account myAccount --rg myRG --location eastus --env production"
    echo "  $0 status --account myAccount --rg myRG"
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
    local policy_name=""
    local vault_name=""
    local backup_name=""
    local resource_group=""
    local location=""
    local daily_backups=""
    local weekly_backups=""
    local monthly_backups=""
    local enabled=""
    local volume_id=""
    local environment=""
    local force="false"
    local output_format="table"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --account)
                account_name="$2"
                shift 2
                ;;
            --name)
                case "$command" in
                    "create-vault"|"show-vault"|"delete-vault")
                        vault_name="$2"
                        ;;
                    "create-backup"|"show-backup"|"delete-backup")
                        backup_name="$2"
                        ;;
                    *)
                        policy_name="$2"
                        ;;
                esac
                shift 2
                ;;
            --vault)
                vault_name="$2"
                shift 2
                ;;
            --rg|--resource-group)
                resource_group="$2"
                shift 2
                ;;
            --location)
                location="$2"
                shift 2
                ;;
            --daily)
                daily_backups="$2"
                shift 2
                ;;
            --weekly)
                weekly_backups="$2"
                shift 2
                ;;
            --monthly)
                monthly_backups="$2"
                shift 2
                ;;
            --enabled)
                enabled="$2"
                shift 2
                ;;
            --volume-id)
                volume_id="$2"
                shift 2
                ;;
            --env)
                environment="$2"
                shift 2
                ;;
            --force)
                force="true"
                shift
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
        create)
            create_backup_policy "$account_name" "$policy_name" "$resource_group" "$location" "$daily_backups" "$weekly_backups" "$monthly_backups" "$enabled"
            ;;
        create-enterprise)
            create_enterprise_backup_policy "$account_name" "$policy_name" "$resource_group" "$location"
            ;;
        create-dev)
            create_dev_backup_policy "$account_name" "$policy_name" "$resource_group" "$location"
            ;;
        update)
            update_backup_policy "$account_name" "$policy_name" "$resource_group" "$daily_backups" "$weekly_backups" "$monthly_backups" "$enabled"
            ;;
        delete)
            delete_backup_policy "$account_name" "$policy_name" "$resource_group" "$force"
            ;;
        show)
            show_backup_policy "$account_name" "$policy_name" "$resource_group" "$output_format"
            ;;
        list)
            list_backup_policies "$account_name" "$resource_group" "$output_format"
            ;;
        create-vault)
            create_backup_vault "$account_name" "$vault_name" "$resource_group" "$location"
            ;;
        create-backup)
            create_manual_backup "$account_name" "$vault_name" "$backup_name" "$volume_id" "$resource_group"
            ;;
        migrate-backups)
            migrate_backups_to_vault "$account_name" "$vault_name" "$resource_group"
            ;;
        strategy)
            create_backup_strategy "$account_name" "$resource_group" "$location" "$environment"
            ;;
        status)
            show_backup_status "$account_name" "$resource_group"
            ;;
        validate)
            validate_backup_policy "$account_name" "$policy_name" "$resource_group"
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
