#!/bin/bash
# Azure NetApp Files - Quota Management
# Create, manage, and monitor volume quota rules and limits

set -e

# Configuration
SCRIPT_NAME="ANF Quota Management"
LOG_FILE="anf-quota-management-$(date +%Y%m%d-%H%M%S).log"

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

# Function to create volume quota rule
create_quota_rule() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local quota_rule_name="$4"
    local resource_group="$5"
    local quota_size="$6"
    local quota_type="${7:-IndividualUserQuota}"
    local quota_target="$8"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$quota_rule_name" ] || [ -z "$resource_group" ] || [ -z "$quota_size" ]; then
        error "Account name, pool name, volume name, quota rule name, resource group, and quota size are required"
        return 1
    fi
    
    info "Creating quota rule: $quota_rule_name"
    
    local cmd="az netappfiles volume quota-rule create"
    cmd+=" --account-name '$account_name'"
    cmd+=" --pool-name '$pool_name'"
    cmd+=" --volume-name '$volume_name'"
    cmd+=" --quota-rule-name '$quota_rule_name'"
    cmd+=" --resource-group '$resource_group'"
    cmd+=" --quota-size-in-kibs $quota_size"
    cmd+=" --quota-type '$quota_type'"
    
    if [ -n "$quota_target" ]; then
        cmd+=" --quota-target '$quota_target'"
    fi
    
    log "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        log "Quota rule '$quota_rule_name' created successfully"
        show_quota_rule "$account_name" "$pool_name" "$volume_name" "$quota_rule_name" "$resource_group"
    else
        error "Failed to create quota rule '$quota_rule_name'"
        return 1
    fi
}

# Function to create user quota rule
create_user_quota() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local user_id="$4"
    local quota_size="$5"
    local resource_group="$6"
    local quota_rule_name="${user_id}-quota"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$user_id" ] || [ -z "$quota_size" ] || [ -z "$resource_group" ]; then
        error "All parameters are required for user quota creation"
        return 1
    fi
    
    info "Creating user quota for user: $user_id"
    
    create_quota_rule "$account_name" "$pool_name" "$volume_name" "$quota_rule_name" "$resource_group" "$quota_size" "IndividualUserQuota" "$user_id"
}

# Function to create group quota rule
create_group_quota() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local group_id="$4"
    local quota_size="$5"
    local resource_group="$6"
    local quota_rule_name="${group_id}-quota"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$group_id" ] || [ -z "$quota_size" ] || [ -z "$resource_group" ]; then
        error "All parameters are required for group quota creation"
        return 1
    fi
    
    info "Creating group quota for group: $group_id"
    
    create_quota_rule "$account_name" "$pool_name" "$volume_name" "$quota_rule_name" "$resource_group" "$quota_size" "IndividualGroupQuota" "$group_id"
}

# Function to create default user quota
create_default_user_quota() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local quota_size="$4"
    local resource_group="$5"
    local quota_rule_name="default-user-quota"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$quota_size" ] || [ -z "$resource_group" ]; then
        error "All parameters are required for default user quota creation"
        return 1
    fi
    
    info "Creating default user quota"
    
    create_quota_rule "$account_name" "$pool_name" "$volume_name" "$quota_rule_name" "$resource_group" "$quota_size" "DefaultUserQuota" ""
}

# Function to create default group quota
create_default_group_quota() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local quota_size="$4"
    local resource_group="$5"
    local quota_rule_name="default-group-quota"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$quota_size" ] || [ -z "$resource_group" ]; then
        error "All parameters are required for default group quota creation"
        return 1
    fi
    
    info "Creating default group quota"
    
    create_quota_rule "$account_name" "$pool_name" "$volume_name" "$quota_rule_name" "$resource_group" "$quota_size" "DefaultGroupQuota" ""
}

# Function to update quota rule
update_quota_rule() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local quota_rule_name="$4"
    local resource_group="$5"
    local quota_size="$6"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$quota_rule_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, quota rule name, and resource group are required"
        return 1
    fi
    
    info "Updating quota rule: $quota_rule_name"
    
    local cmd="az netappfiles volume quota-rule update"
    cmd+=" --account-name '$account_name'"
    cmd+=" --pool-name '$pool_name'"
    cmd+=" --volume-name '$volume_name'"
    cmd+=" --quota-rule-name '$quota_rule_name'"
    cmd+=" --resource-group '$resource_group'"
    
    if [ -n "$quota_size" ]; then
        cmd+=" --quota-size-in-kibs $quota_size"
    fi
    
    log "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        log "Quota rule '$quota_rule_name' updated successfully"
    else
        error "Failed to update quota rule '$quota_rule_name'"
        return 1
    fi
}

# Function to show quota rule details
show_quota_rule() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local quota_rule_name="$4"
    local resource_group="$5"
    local output_format="${6:-table}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$quota_rule_name" ] || [ -z "$resource_group" ]; then
        error "All parameters are required to show quota rule"
        return 1
    fi
    
    info "Getting quota rule details: $quota_rule_name"
    
    az netappfiles volume quota-rule show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --quota-rule-name "$quota_rule_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to list all quota rules for a volume
list_quota_rules() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local output_format="${5:-table}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Listing quota rules for volume: $volume_name"
    
    az netappfiles volume quota-rule list \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to delete quota rule
delete_quota_rule() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local quota_rule_name="$4"
    local resource_group="$5"
    local force="${6:-false}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$quota_rule_name" ] || [ -z "$resource_group" ]; then
        error "All parameters are required to delete quota rule"
        return 1
    fi
    
    if [ "$force" != "true" ]; then
        read -p "Are you sure you want to delete quota rule '$quota_rule_name'? (y/N): " confirmation
        if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
            warn "Quota rule deletion cancelled"
            return 0
        fi
    fi
    
    info "Deleting quota rule: $quota_rule_name"
    
    az netappfiles volume quota-rule delete \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --quota-rule-name "$quota_rule_name" \
        --resource-group "$resource_group" \
        --yes
    
    if [ $? -eq 0 ]; then
        log "Quota rule '$quota_rule_name' deleted successfully"
    else
        error "Failed to delete quota rule '$quota_rule_name'"
        return 1
    fi
}

# Function to get quota limits
get_quota_limits() {
    local location="$1"
    local output_format="${2:-table}"
    
    if [ -z "$location" ]; then
        error "Location is required"
        return 1
    fi
    
    info "Getting quota limits for location: $location"
    
    az netappfiles quota-limit list \
        --location "$location" \
        --output "$output_format"
}

# Function to show specific quota limit
show_quota_limit() {
    local location="$1"
    local quota_limit_name="$2"
    local output_format="${3:-table}"
    
    if [ -z "$location" ] || [ -z "$quota_limit_name" ]; then
        error "Location and quota limit name are required"
        return 1
    fi
    
    info "Getting quota limit: $quota_limit_name"
    
    az netappfiles quota-limit show \
        --location "$location" \
        --quota-limit-name "$quota_limit_name" \
        --output "$output_format"
}

# Function to get volume quota report
get_quota_report() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local output_format="${5:-table}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Getting quota report for volume: $volume_name"
    
    # Check if the command exists (extension required)
    if az netappfiles volume list-quota-report --help &>/dev/null; then
        az netappfiles volume list-quota-report \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --resource-group "$resource_group" \
            --output "$output_format"
    else
        warn "Quota report command not available. Install netappfiles-preview extension."
        list_quota_rules "$account_name" "$pool_name" "$volume_name" "$resource_group" "$output_format"
    fi
}

# Function to create quota management strategy
create_quota_strategy() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local strategy="${5:-balanced}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    log "Creating quota management strategy: $strategy"
    
    case "$strategy" in
        "strict")
            # Strict quotas for high-security environments
            create_default_user_quota "$account_name" "$pool_name" "$volume_name" "1048576" "$resource_group"    # 1GB default user
            create_default_group_quota "$account_name" "$pool_name" "$volume_name" "10485760" "$resource_group"  # 10GB default group
            ;;
        "balanced")
            # Balanced quotas for general use
            create_default_user_quota "$account_name" "$pool_name" "$volume_name" "5242880" "$resource_group"    # 5GB default user
            create_default_group_quota "$account_name" "$pool_name" "$volume_name" "52428800" "$resource_group"  # 50GB default group
            ;;
        "permissive")
            # Permissive quotas for development/testing
            create_default_user_quota "$account_name" "$pool_name" "$volume_name" "10485760" "$resource_group"   # 10GB default user
            create_default_group_quota "$account_name" "$pool_name" "$volume_name" "104857600" "$resource_group" # 100GB default group
            ;;
        *)
            error "Unknown strategy: $strategy. Use 'strict', 'balanced', or 'permissive'"
            return 1
            ;;
    esac
    
    log "Quota strategy '$strategy' applied successfully"
}

# Function to bulk create user quotas
bulk_create_user_quotas() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local quota_size="$5"
    local users_file="$6"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ] || [ -z "$quota_size" ] || [ -z "$users_file" ]; then
        error "All parameters including users file are required"
        return 1
    fi
    
    if [ ! -f "$users_file" ]; then
        error "Users file not found: $users_file"
        return 1
    fi
    
    log "Creating bulk user quotas from file: $users_file"
    
    local success_count=0
    local error_count=0
    
    while IFS= read -r user_id; do
        # Skip empty lines and comments
        [[ -z "$user_id" || "$user_id" =~ ^#.*$ ]] && continue
        
        info "Creating quota for user: $user_id"
        
        if create_user_quota "$account_name" "$pool_name" "$volume_name" "$user_id" "$quota_size" "$resource_group"; then
            ((success_count++))
        else
            ((error_count++))
            warn "Failed to create quota for user: $user_id"
        fi
    done < "$users_file"
    
    log "Bulk quota creation completed: $success_count successful, $error_count failed"
}

# Function to monitor quota usage
monitor_quota_usage() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local threshold="${5:-80}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Monitoring quota usage (threshold: ${threshold}%)"
    
    # Get quota report if available
    echo -e "\n${BLUE}=== Current Quota Rules ===${NC}"
    list_quota_rules "$account_name" "$pool_name" "$volume_name" "$resource_group" "table"
    
    # Get volume usage information
    echo -e "\n${BLUE}=== Volume Usage Information ===${NC}"
    local volume_data=$(az netappfiles volume show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --output json)
    
    local usage_threshold=$(echo "$volume_data" | jq -r '.usageThreshold // 0')
    local actual_usage=$(echo "$volume_data" | jq -r '.actualSizeUsed // 0')
    
    if [ "$usage_threshold" -gt 0 ] && [ "$actual_usage" -gt 0 ]; then
        local usage_percent=$((actual_usage * 100 / usage_threshold))
        
        echo "Volume Size: $(($usage_threshold / 1073741824)) GB"
        echo "Used Space: $(($actual_usage / 1073741824)) GB"
        echo "Usage Percentage: ${usage_percent}%"
        
        if [ "$usage_percent" -ge "$threshold" ]; then
            warn "Volume usage (${usage_percent}%) exceeds threshold (${threshold}%)"
        else
            log "Volume usage (${usage_percent}%) is within threshold (${threshold}%)"
        fi
    else
        warn "Unable to calculate usage percentage"
    fi
}

# Function to validate quota configuration
validate_quota_configuration() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Validating quota configuration for volume: $volume_name"
    
    # Get all quota rules
    local quota_rules=$(az netappfiles volume quota-rule list \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --output json)
    
    local rule_count=$(echo "$quota_rules" | jq length)
    
    echo -e "\n${BLUE}=== Quota Configuration Validation ===${NC}"
    echo "Volume: $volume_name"
    echo "Total Quota Rules: $rule_count"
    
    if [ "$rule_count" -eq 0 ]; then
        warn "No quota rules configured for this volume"
        return 0
    fi
    
    # Check for default quotas
    local has_default_user=$(echo "$quota_rules" | jq -r '.[] | select(.quotaType == "DefaultUserQuota") | .name' | wc -l)
    local has_default_group=$(echo "$quota_rules" | jq -r '.[] | select(.quotaType == "DefaultGroupQuota") | .name' | wc -l)
    
    echo "Default User Quota: $([ "$has_default_user" -gt 0 ] && echo "Yes" || echo "No")"
    echo "Default Group Quota: $([ "$has_default_group" -gt 0 ] && echo "Yes" || echo "No")"
    
    # List quota types
    echo -e "\n${BLUE}=== Quota Rules by Type ===${NC}"
    echo "$quota_rules" | jq -r '.[] | "\(.quotaType): \(.quotaSizeInKiBs) KiB (\(.name))"' | sort
    
    log "Quota configuration validation completed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG --size SIZE [options]"
    echo "  create-user --account ACCOUNT --pool POOL --volume VOLUME --user USER --size SIZE --rg RG"
    echo "  create-group --account ACCOUNT --pool POOL --volume VOLUME --group GROUP --size SIZE --rg RG"
    echo "  create-default-user --account ACCOUNT --pool POOL --volume VOLUME --size SIZE --rg RG"
    echo "  create-default-group --account ACCOUNT --pool POOL --volume VOLUME --size SIZE --rg RG"
    echo "  update --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG [--size SIZE]"
    echo "  delete --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG [--force]"
    echo "  show --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG"
    echo "  list --account ACCOUNT --pool POOL --volume VOLUME --rg RG"
    echo "  limits --location LOCATION"
    echo "  limit --location LOCATION --name NAME"
    echo "  report --account ACCOUNT --pool POOL --volume VOLUME --rg RG"
    echo "  strategy --account ACCOUNT --pool POOL --volume VOLUME --rg RG --strategy STRATEGY"
    echo "  bulk-users --account ACCOUNT --pool POOL --volume VOLUME --rg RG --size SIZE --file FILE"
    echo "  monitor --account ACCOUNT --pool POOL --volume VOLUME --rg RG [--threshold PERCENT]"
    echo "  validate --account ACCOUNT --pool POOL --volume VOLUME --rg RG"
    echo ""
    echo "Options:"
    echo "  --account ACCOUNT              NetApp account name"
    echo "  --pool POOL                    Capacity pool name"
    echo "  --volume VOLUME                Volume name"
    echo "  --name NAME                    Quota rule name"
    echo "  --user USER                    User ID for quota"
    echo "  --group GROUP                  Group ID for quota"
    echo "  --rg, --resource-group RG      Resource group"
    echo "  --size SIZE                    Quota size in KiB"
    echo "  --type TYPE                    Quota type (IndividualUserQuota/IndividualGroupQuota/DefaultUserQuota/DefaultGroupQuota)"
    echo "  --target TARGET                Quota target (user ID or group ID)"
    echo "  --location LOCATION            Azure location"
    echo "  --strategy STRATEGY            Quota strategy (strict/balanced/permissive)"
    echo "  --file FILE                    File containing user/group IDs"
    echo "  --threshold PERCENT            Usage threshold percentage (default: 80)"
    echo "  --force                        Force deletion without confirmation"
    echo "  --format FORMAT                Output format (table, json, yaml, tsv)"
    echo ""
    echo "Examples:"
    echo "  $0 create-user --account myAccount --pool myPool --volume myVolume --user 1001 --size 5242880 --rg myRG"
    echo "  $0 strategy --account myAccount --pool myPool --volume myVolume --rg myRG --strategy balanced"
    echo "  $0 monitor --account myAccount --pool myPool --volume myVolume --rg myRG --threshold 85"
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
    local quota_rule_name=""
    local resource_group=""
    local quota_size=""
    local quota_type=""
    local quota_target=""
    local user_id=""
    local group_id=""
    local location=""
    local strategy=""
    local users_file=""
    local threshold="80"
    local force="false"
    local output_format="table"
    
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
            --name)
                quota_rule_name="$2"
                shift 2
                ;;
            --user)
                user_id="$2"
                shift 2
                ;;
            --group)
                group_id="$2"
                shift 2
                ;;
            --rg|--resource-group)
                resource_group="$2"
                shift 2
                ;;
            --size)
                quota_size="$2"
                shift 2
                ;;
            --type)
                quota_type="$2"
                shift 2
                ;;
            --target)
                quota_target="$2"
                shift 2
                ;;
            --location)
                location="$2"
                shift 2
                ;;
            --strategy)
                strategy="$2"
                shift 2
                ;;
            --file)
                users_file="$2"
                shift 2
                ;;
            --threshold)
                threshold="$2"
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
            create_quota_rule "$account_name" "$pool_name" "$volume_name" "$quota_rule_name" "$resource_group" "$quota_size" "$quota_type" "$quota_target"
            ;;
        create-user)
            create_user_quota "$account_name" "$pool_name" "$volume_name" "$user_id" "$quota_size" "$resource_group"
            ;;
        create-group)
            create_group_quota "$account_name" "$pool_name" "$volume_name" "$group_id" "$quota_size" "$resource_group"
            ;;
        create-default-user)
            create_default_user_quota "$account_name" "$pool_name" "$volume_name" "$quota_size" "$resource_group"
            ;;
        create-default-group)
            create_default_group_quota "$account_name" "$pool_name" "$volume_name" "$quota_size" "$resource_group"
            ;;
        update)
            update_quota_rule "$account_name" "$pool_name" "$volume_name" "$quota_rule_name" "$resource_group" "$quota_size"
            ;;
        delete)
            delete_quota_rule "$account_name" "$pool_name" "$volume_name" "$quota_rule_name" "$resource_group" "$force"
            ;;
        show)
            show_quota_rule "$account_name" "$pool_name" "$volume_name" "$quota_rule_name" "$resource_group" "$output_format"
            ;;
        list)
            list_quota_rules "$account_name" "$pool_name" "$volume_name" "$resource_group" "$output_format"
            ;;
        limits)
            get_quota_limits "$location" "$output_format"
            ;;
        limit)
            show_quota_limit "$location" "$quota_rule_name" "$output_format"
            ;;
        report)
            get_quota_report "$account_name" "$pool_name" "$volume_name" "$resource_group" "$output_format"
            ;;
        strategy)
            create_quota_strategy "$account_name" "$pool_name" "$volume_name" "$resource_group" "$strategy"
            ;;
        bulk-users)
            bulk_create_user_quotas "$account_name" "$pool_name" "$volume_name" "$resource_group" "$quota_size" "$users_file"
            ;;
        monitor)
            monitor_quota_usage "$account_name" "$pool_name" "$volume_name" "$resource_group" "$threshold"
            ;;
        validate)
            validate_quota_configuration "$account_name" "$pool_name" "$volume_name" "$resource_group"
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
