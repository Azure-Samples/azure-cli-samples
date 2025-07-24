#!/bin/bash
# Azure NetApp Files - Availability and Name Checks
# Check resource name availability, file path availability, and quota availability

set -e

# Configuration
SCRIPT_NAME="ANF Availability Checks"
LOG_FILE="anf-availability-checks-$(date +%Y%m%d-%H%M%S).log"

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

# Function to check name availability for NetApp account
check_account_name_availability() {
    local account_name="$1"
    local resource_group="$2"
    local location="$3"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Account name, resource group, and location are required"
        return 1
    fi
    
    info "Checking account name availability: $account_name"
    
    local result=$(az netappfiles check-name-availability \
        --name "$account_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --type "Microsoft.NetApp/netAppAccounts" \
        --output json)
    
    local available=$(echo "$result" | jq -r '.nameAvailable')
    local reason=$(echo "$result" | jq -r '.reason // "N/A"')
    local message=$(echo "$result" | jq -r '.message // "N/A"')
    
    echo -e "\n${BLUE}=== Account Name Availability Check ===${NC}"
    echo "Account Name: $account_name"
    echo "Available: $available"
    echo "Reason: $reason"
    echo "Message: $message"
    
    if [ "$available" = "true" ]; then
        log "Account name '$account_name' is available"
        return 0
    else
        warn "Account name '$account_name' is not available: $reason - $message"
        return 1
    fi
}

# Function to check name availability for capacity pool
check_pool_name_availability() {
    local pool_name="$1"
    local resource_group="$2"
    local location="$3"
    
    if [ -z "$pool_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Pool name, resource group, and location are required"
        return 1
    fi
    
    info "Checking pool name availability: $pool_name"
    
    local result=$(az netappfiles check-name-availability \
        --name "$pool_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --type "Microsoft.NetApp/netAppAccounts/capacityPools" \
        --output json)
    
    local available=$(echo "$result" | jq -r '.nameAvailable')
    local reason=$(echo "$result" | jq -r '.reason // "N/A"')
    local message=$(echo "$result" | jq -r '.message // "N/A"')
    
    echo -e "\n${BLUE}=== Pool Name Availability Check ===${NC}"
    echo "Pool Name: $pool_name"
    echo "Available: $available"
    echo "Reason: $reason"
    echo "Message: $message"
    
    if [ "$available" = "true" ]; then
        log "Pool name '$pool_name' is available"
        return 0
    else
        warn "Pool name '$pool_name' is not available: $reason - $message"
        return 1
    fi
}

# Function to check name availability for volume
check_volume_name_availability() {
    local volume_name="$1"
    local resource_group="$2"
    local location="$3"
    
    if [ -z "$volume_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Volume name, resource group, and location are required"
        return 1
    fi
    
    info "Checking volume name availability: $volume_name"
    
    local result=$(az netappfiles check-name-availability \
        --name "$volume_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --type "Microsoft.NetApp/netAppAccounts/capacityPools/volumes" \
        --output json)
    
    local available=$(echo "$result" | jq -r '.nameAvailable')
    local reason=$(echo "$result" | jq -r '.reason // "N/A"')
    local message=$(echo "$result" | jq -r '.message // "N/A"')
    
    echo -e "\n${BLUE}=== Volume Name Availability Check ===${NC}"
    echo "Volume Name: $volume_name"
    echo "Available: $available"
    echo "Reason: $reason"
    echo "Message: $message"
    
    if [ "$available" = "true" ]; then
        log "Volume name '$volume_name' is available"
        return 0
    else
        warn "Volume name '$volume_name' is not available: $reason - $message"
        return 1
    fi
}

# Function to check name availability for snapshot
check_snapshot_name_availability() {
    local snapshot_name="$1"
    local resource_group="$2"
    local location="$3"
    
    if [ -z "$snapshot_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Snapshot name, resource group, and location are required"
        return 1
    fi
    
    info "Checking snapshot name availability: $snapshot_name"
    
    local result=$(az netappfiles check-name-availability \
        --name "$snapshot_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --type "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/snapshots" \
        --output json)
    
    local available=$(echo "$result" | jq -r '.nameAvailable')
    local reason=$(echo "$result" | jq -r '.reason // "N/A"')
    local message=$(echo "$result" | jq -r '.message // "N/A"')
    
    echo -e "\n${BLUE}=== Snapshot Name Availability Check ===${NC}"
    echo "Snapshot Name: $snapshot_name"
    echo "Available: $available"
    echo "Reason: $reason"
    echo "Message: $message"
    
    if [ "$available" = "true" ]; then
        log "Snapshot name '$snapshot_name' is available"
        return 0
    else
        warn "Snapshot name '$snapshot_name' is not available: $reason - $message"
        return 1
    fi
}

# Function to check file path availability
check_file_path_availability() {
    local file_path="$1"
    local subnet_id="$2"
    local location="$3"
    local availability_zone="$4"
    
    if [ -z "$file_path" ] || [ -z "$subnet_id" ] || [ -z "$location" ]; then
        error "File path, subnet ID, and location are required"
        return 1
    fi
    
    info "Checking file path availability: $file_path"
    
    local cmd="az netappfiles check-file-path-availability"
    cmd+=" --name '$file_path'"
    cmd+=" --subnet-id '$subnet_id'"
    cmd+=" --location '$location'"
    
    if [ -n "$availability_zone" ]; then
        cmd+=" --availability-zone '$availability_zone'"
    fi
    
    local result=$(eval "$cmd --output json")
    
    local available=$(echo "$result" | jq -r '.isAvailable')
    local reason=$(echo "$result" | jq -r '.reason // "N/A"')
    local message=$(echo "$result" | jq -r '.message // "N/A"')
    
    echo -e "\n${BLUE}=== File Path Availability Check ===${NC}"
    echo "File Path: $file_path"
    echo "Subnet ID: $subnet_id"
    echo "Location: $location"
    if [ -n "$availability_zone" ]; then
        echo "Availability Zone: $availability_zone"
    fi
    echo "Available: $available"
    echo "Reason: $reason"
    echo "Message: $message"
    
    if [ "$available" = "true" ]; then
        log "File path '$file_path' is available"
        return 0
    else
        warn "File path '$file_path' is not available: $reason - $message"
        return 1
    fi
}

# Function to check quota availability for NetApp account
check_account_quota_availability() {
    local account_name="$1"
    local resource_group="$2"
    local location="$3"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Account name, resource group, and location are required"
        return 1
    fi
    
    info "Checking account quota availability: $account_name"
    
    local result=$(az netappfiles check-quota-availability \
        --name "$account_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --type "Microsoft.NetApp/netAppAccounts" \
        --output json)
    
    local available=$(echo "$result" | jq -r '.isAvailable')
    local reason=$(echo "$result" | jq -r '.reason // "N/A"')
    local message=$(echo "$result" | jq -r '.message // "N/A"')
    
    echo -e "\n${BLUE}=== Account Quota Availability Check ===${NC}"
    echo "Account Name: $account_name"
    echo "Available: $available"
    echo "Reason: $reason"
    echo "Message: $message"
    
    if [ "$available" = "true" ]; then
        log "Account quota for '$account_name' is available"
        return 0
    else
        warn "Account quota for '$account_name' is not available: $reason - $message"
        return 1
    fi
}

# Function to check quota availability for capacity pool
check_pool_quota_availability() {
    local pool_name="$1"
    local resource_group="$2"
    local location="$3"
    
    if [ -z "$pool_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Pool name, resource group, and location are required"
        return 1
    fi
    
    info "Checking pool quota availability: $pool_name"
    
    local result=$(az netappfiles check-quota-availability \
        --name "$pool_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --type "Microsoft.NetApp/netAppAccounts/capacityPools" \
        --output json)
    
    local available=$(echo "$result" | jq -r '.isAvailable')
    local reason=$(echo "$result" | jq -r '.reason // "N/A"')
    local message=$(echo "$result" | jq -r '.message // "N/A"')
    
    echo -e "\n${BLUE}=== Pool Quota Availability Check ===${NC}"
    echo "Pool Name: $pool_name"
    echo "Available: $available"
    echo "Reason: $reason"
    echo "Message: $message"
    
    if [ "$available" = "true" ]; then
        log "Pool quota for '$pool_name' is available"
        return 0
    else
        warn "Pool quota for '$pool_name' is not available: $reason - $message"
        return 1
    fi
}

# Function to check quota availability for volume
check_volume_quota_availability() {
    local volume_name="$1"
    local resource_group="$2"
    local location="$3"
    
    if [ -z "$volume_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Volume name, resource group, and location are required"
        return 1
    fi
    
    info "Checking volume quota availability: $volume_name"
    
    local result=$(az netappfiles check-quota-availability \
        --name "$volume_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --type "Microsoft.NetApp/netAppAccounts/capacityPools/volumes" \
        --output json)
    
    local available=$(echo "$result" | jq -r '.isAvailable')
    local reason=$(echo "$result" | jq -r '.reason // "N/A"')
    local message=$(echo "$result" | jq -r '.message // "N/A"')
    
    echo -e "\n${BLUE}=== Volume Quota Availability Check ===${NC}"
    echo "Volume Name: $volume_name"
    echo "Available: $available"
    echo "Reason: $reason"
    echo "Message: $message"
    
    if [ "$available" = "true" ]; then
        log "Volume quota for '$volume_name' is available"
        return 0
    else
        warn "Volume quota for '$volume_name' is not available: $reason - $message"
        return 1
    fi
}

# Function to check all availability types for a resource
check_all_availability() {
    local resource_name="$1"
    local resource_type="$2"
    local resource_group="$3"
    local location="$4"
    local subnet_id="$5"
    local availability_zone="$6"
    
    if [ -z "$resource_name" ] || [ -z "$resource_type" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Resource name, type, resource group, and location are required"
        return 1
    fi
    
    log "Performing comprehensive availability check for: $resource_name ($resource_type)"
    
    local name_available=false
    local quota_available=false
    local file_path_available=false
    
    # Check name availability
    case "$resource_type" in
        "account")
            if check_account_name_availability "$resource_name" "$resource_group" "$location"; then
                name_available=true
            fi
            if check_account_quota_availability "$resource_name" "$resource_group" "$location"; then
                quota_available=true
            fi
            ;;
        "pool")
            if check_pool_name_availability "$resource_name" "$resource_group" "$location"; then
                name_available=true
            fi
            if check_pool_quota_availability "$resource_name" "$resource_group" "$location"; then
                quota_available=true
            fi
            ;;
        "volume")
            if check_volume_name_availability "$resource_name" "$resource_group" "$location"; then
                name_available=true
            fi
            if check_volume_quota_availability "$resource_name" "$resource_group" "$location"; then
                quota_available=true
            fi
            # Check file path availability if subnet_id is provided
            if [ -n "$subnet_id" ]; then
                if check_file_path_availability "$resource_name" "$subnet_id" "$location" "$availability_zone"; then
                    file_path_available=true
                fi
            fi
            ;;
        "snapshot")
            if check_snapshot_name_availability "$resource_name" "$resource_group" "$location"; then
                name_available=true
            fi
            ;;
        *)
            error "Unknown resource type: $resource_type"
            return 1
            ;;
    esac
    
    # Summary
    echo -e "\n${GREEN}=== Comprehensive Availability Summary ===${NC}"
    echo "Resource: $resource_name"
    echo "Type: $resource_type"
    echo "Name Available: $([ "$name_available" = true ] && echo "✓ Yes" || echo "✗ No")"
    echo "Quota Available: $([ "$quota_available" = true ] && echo "✓ Yes" || echo "✗ No")"
    if [ "$resource_type" = "volume" ] && [ -n "$subnet_id" ]; then
        echo "File Path Available: $([ "$file_path_available" = true ] && echo "✓ Yes" || echo "✗ No")"
    fi
    
    # Overall availability
    local overall_available=true
    if [ "$name_available" != true ] || [ "$quota_available" != true ]; then
        overall_available=false
    fi
    if [ "$resource_type" = "volume" ] && [ -n "$subnet_id" ] && [ "$file_path_available" != true ]; then
        overall_available=false
    fi
    
    echo -e "\nOverall Status: $([ "$overall_available" = true ] && echo -e "${GREEN}✓ Available${NC}" || echo -e "${RED}✗ Not Available${NC}")"
    
    if [ "$overall_available" = true ]; then
        log "All availability checks passed for '$resource_name'"
        return 0
    else
        warn "One or more availability checks failed for '$resource_name'"
        return 1
    fi
}

# Function to bulk check names from file
bulk_check_names() {
    local resource_type="$1"
    local resource_group="$2"
    local location="$3"
    local names_file="$4"
    
    if [ -z "$resource_type" ] || [ -z "$resource_group" ] || [ -z "$location" ] || [ -z "$names_file" ]; then
        error "Resource type, resource group, location, and names file are required"
        return 1
    fi
    
    if [ ! -f "$names_file" ]; then
        error "Names file not found: $names_file"
        return 1
    fi
    
    log "Performing bulk name availability check from file: $names_file"
    
    local available_count=0
    local unavailable_count=0
    
    echo -e "\n${BLUE}=== Bulk Name Availability Check Results ===${NC}"
    printf "%-30s %-15s %-50s\n" "Resource Name" "Available" "Message"
    printf "%-30s %-15s %-50s\n" "-------------" "---------" "-------"
    
    while IFS= read -r resource_name; do
        # Skip empty lines and comments
        [[ -z "$resource_name" || "$resource_name" =~ ^#.*$ ]] && continue
        
        local result=""
        local available=""
        local message=""
        
        case "$resource_type" in
            "account")
                result=$(az netappfiles check-name-availability \
                    --name "$resource_name" \
                    --resource-group "$resource_group" \
                    --location "$location" \
                    --type "Microsoft.NetApp/netAppAccounts" \
                    --output json 2>/dev/null)
                ;;
            "pool")
                result=$(az netappfiles check-name-availability \
                    --name "$resource_name" \
                    --resource-group "$resource_group" \
                    --location "$location" \
                    --type "Microsoft.NetApp/netAppAccounts/capacityPools" \
                    --output json 2>/dev/null)
                ;;
            "volume")
                result=$(az netappfiles check-name-availability \
                    --name "$resource_name" \
                    --resource-group "$resource_group" \
                    --location "$location" \
                    --type "Microsoft.NetApp/netAppAccounts/capacityPools/volumes" \
                    --output json 2>/dev/null)
                ;;
            "snapshot")
                result=$(az netappfiles check-name-availability \
                    --name "$resource_name" \
                    --resource-group "$resource_group" \
                    --location "$location" \
                    --type "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/snapshots" \
                    --output json 2>/dev/null)
                ;;
        esac
        
        if [ -n "$result" ]; then
            available=$(echo "$result" | jq -r '.nameAvailable')
            message=$(echo "$result" | jq -r '.reason // .message // "N/A"')
            
            if [ "$available" = "true" ]; then
                ((available_count++))
                printf "%-30s %-15s %-50s\n" "$resource_name" "✓ Yes" "$message"
            else
                ((unavailable_count++))
                printf "%-30s %-15s %-50s\n" "$resource_name" "✗ No" "$message"
            fi
        else
            ((unavailable_count++))
            printf "%-30s %-15s %-50s\n" "$resource_name" "✗ Error" "Failed to check"
        fi
    done < "$names_file"
    
    echo -e "\n${BLUE}=== Bulk Check Summary ===${NC}"
    echo "Total Checked: $((available_count + unavailable_count))"
    echo "Available: $available_count"
    echo "Unavailable: $unavailable_count"
    
    log "Bulk name availability check completed: $available_count available, $unavailable_count unavailable"
}

# Function to generate available names
generate_available_names() {
    local base_name="$1"
    local resource_type="$2"
    local resource_group="$3"
    local location="$4"
    local count="${5:-5}"
    
    if [ -z "$base_name" ] || [ -z "$resource_type" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Base name, resource type, resource group, and location are required"
        return 1
    fi
    
    log "Generating available names based on: $base_name"
    
    echo -e "\n${BLUE}=== Available Name Suggestions ===${NC}"
    local found_count=0
    local attempt=1
    
    while [ $found_count -lt $count ] && [ $attempt -le 50 ]; do
        local test_name=""
        
        case $attempt in
            1) test_name="$base_name" ;;
            2) test_name="${base_name}1" ;;
            3) test_name="${base_name}01" ;;
            4) test_name="${base_name}-1" ;;
            5) test_name="${base_name}-01" ;;
            6) test_name="${base_name}2" ;;
            7) test_name="${base_name}02" ;;
            8) test_name="${base_name}-2" ;;
            9) test_name="${base_name}-02" ;;
            10) test_name="${base_name}dev" ;;
            11) test_name="${base_name}-dev" ;;
            12) test_name="${base_name}test" ;;
            13) test_name="${base_name}-test" ;;
            14) test_name="${base_name}prod" ;;
            15) test_name="${base_name}-prod" ;;
            *) 
                # Generate random suffix
                local suffix=$(openssl rand -hex 2)
                test_name="${base_name}-${suffix}"
                ;;
        esac
        
        # Check availability
        local result=""
        case "$resource_type" in
            "account")
                result=$(az netappfiles check-name-availability \
                    --name "$test_name" \
                    --resource-group "$resource_group" \
                    --location "$location" \
                    --type "Microsoft.NetApp/netAppAccounts" \
                    --output json 2>/dev/null)
                ;;
            "pool")
                result=$(az netappfiles check-name-availability \
                    --name "$test_name" \
                    --resource-group "$resource_group" \
                    --location "$location" \
                    --type "Microsoft.NetApp/netAppAccounts/capacityPools" \
                    --output json 2>/dev/null)
                ;;
            "volume")
                result=$(az netappfiles check-name-availability \
                    --name "$test_name" \
                    --resource-group "$resource_group" \
                    --location "$location" \
                    --type "Microsoft.NetApp/netAppAccounts/capacityPools/volumes" \
                    --output json 2>/dev/null)
                ;;
            "snapshot")
                result=$(az netappfiles check-name-availability \
                    --name "$test_name" \
                    --resource-group "$resource_group" \
                    --location "$location" \
                    --type "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/snapshots" \
                    --output json 2>/dev/null)
                ;;
        esac
        
        if [ -n "$result" ]; then
            local available=$(echo "$result" | jq -r '.nameAvailable')
            if [ "$available" = "true" ]; then
                echo "$(($found_count + 1)). $test_name"
                ((found_count++))
            fi
        fi
        
        ((attempt++))
    done
    
    if [ $found_count -eq 0 ]; then
        warn "No available names found based on '$base_name'"
    else
        log "Generated $found_count available name suggestions"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  check-name --name NAME --type TYPE --rg RG --location LOCATION"
    echo "  check-quota --name NAME --type TYPE --rg RG --location LOCATION"
    echo "  check-file-path --path PATH --subnet-id ID --location LOCATION [--zone ZONE]"
    echo "  check-all --name NAME --type TYPE --rg RG --location LOCATION [--subnet-id ID] [--zone ZONE]"
    echo "  bulk-names --type TYPE --rg RG --location LOCATION --file FILE"
    echo "  generate-names --base NAME --type TYPE --rg RG --location LOCATION [--count COUNT]"
    echo ""
    echo "Options:"
    echo "  --name NAME                    Resource name to check"
    echo "  --base NAME                    Base name for generation"
    echo "  --type TYPE                    Resource type (account/pool/volume/snapshot)"
    echo "  --rg, --resource-group RG      Resource group"
    echo "  --location LOCATION            Azure location"
    echo "  --path PATH                    File path to check"
    echo "  --subnet-id ID                 Subnet resource ID"
    echo "  --zone ZONE                    Availability zone"
    echo "  --file FILE                    File containing names to check"
    echo "  --count COUNT                  Number of suggestions to generate (default: 5)"
    echo ""
    echo "Examples:"
    echo "  $0 check-name --name myAccount --type account --rg myRG --location eastus"
    echo "  $0 check-all --name myVolume --type volume --rg myRG --location eastus --subnet-id /subscriptions/.../subnets/anf-subnet"
    echo "  $0 generate-names --base myapp --type volume --rg myRG --location eastus --count 10"
    echo "  $0 bulk-names --type account --rg myRG --location eastus --file account-names.txt"
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
    local base_name=""
    local resource_type=""
    local resource_group=""
    local location=""
    local file_path=""
    local subnet_id=""
    local availability_zone=""
    local names_file=""
    local count="5"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                resource_name="$2"
                shift 2
                ;;
            --base)
                base_name="$2"
                shift 2
                ;;
            --type)
                resource_type="$2"
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
            --path)
                file_path="$2"
                shift 2
                ;;
            --subnet-id)
                subnet_id="$2"
                shift 2
                ;;
            --zone)
                availability_zone="$2"
                shift 2
                ;;
            --file)
                names_file="$2"
                shift 2
                ;;
            --count)
                count="$2"
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
        check-name)
            case "$resource_type" in
                "account")
                    check_account_name_availability "$resource_name" "$resource_group" "$location"
                    ;;
                "pool")
                    check_pool_name_availability "$resource_name" "$resource_group" "$location"
                    ;;
                "volume")
                    check_volume_name_availability "$resource_name" "$resource_group" "$location"
                    ;;
                "snapshot")
                    check_snapshot_name_availability "$resource_name" "$resource_group" "$location"
                    ;;
                *)
                    error "Invalid resource type for name check: $resource_type"
                    exit 1
                    ;;
            esac
            ;;
        check-quota)
            case "$resource_type" in
                "account")
                    check_account_quota_availability "$resource_name" "$resource_group" "$location"
                    ;;
                "pool")
                    check_pool_quota_availability "$resource_name" "$resource_group" "$location"
                    ;;
                "volume")
                    check_volume_quota_availability "$resource_name" "$resource_group" "$location"
                    ;;
                *)
                    error "Invalid resource type for quota check: $resource_type"
                    exit 1
                    ;;
            esac
            ;;
        check-file-path)
            check_file_path_availability "$file_path" "$subnet_id" "$location" "$availability_zone"
            ;;
        check-all)
            check_all_availability "$resource_name" "$resource_type" "$resource_group" "$location" "$subnet_id" "$availability_zone"
            ;;
        bulk-names)
            bulk_check_names "$resource_type" "$resource_group" "$location" "$names_file"
            ;;
        generate-names)
            generate_available_names "$base_name" "$resource_type" "$resource_group" "$location" "$count"
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
