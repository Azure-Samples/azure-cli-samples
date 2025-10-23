#!/bin/bash
# Azure NetApp Files - Subvolume Management
# Create, manage, and monitor subvolumes with metadata operations

set -e

# Configuration
SCRIPT_NAME="ANF Subvolume Management"
LOG_FILE="anf-subvolume-management-$(date +%Y%m%d-%H%M%S).log"

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

# Function to create subvolume
create_subvolume() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local subvolume_name="$4"
    local resource_group="$5"
    local path="$6"
    local size="$7"
    local parent_path="$8"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$subvolume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, subvolume name, and resource group are required"
        return 1
    fi
    
    info "Creating subvolume: $subvolume_name"
    
    local cmd="az netappfiles subvolume create"
    cmd+=" --account-name '$account_name'"
    cmd+=" --pool-name '$pool_name'"
    cmd+=" --volume-name '$volume_name'"
    cmd+=" --subvolume-name '$subvolume_name'"
    cmd+=" --resource-group '$resource_group'"
    
    if [ -n "$path" ]; then
        cmd+=" --path '$path'"
    else
        cmd+=" --path '/$subvolume_name'"
    fi
    
    if [ -n "$size" ]; then
        cmd+=" --size $size"
    fi
    
    if [ -n "$parent_path" ]; then
        cmd+=" --parent-path '$parent_path'"
    fi
    
    log "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        log "Subvolume '$subvolume_name' created successfully"
        show_subvolume "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group"
    else
        error "Failed to create subvolume '$subvolume_name'"
        return 1
    fi
}

# Function to create subvolume from clone
create_subvolume_clone() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local subvolume_name="$4"
    local resource_group="$5"
    local parent_path="$6"
    local path="$7"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$subvolume_name" ] || [ -z "$resource_group" ] || [ -z "$parent_path" ]; then
        error "Account name, pool name, volume name, subvolume name, resource group, and parent path are required for cloning"
        return 1
    fi
    
    info "Creating subvolume clone: $subvolume_name from parent: $parent_path"
    
    local cmd="az netappfiles subvolume create"
    cmd+=" --account-name '$account_name'"
    cmd+=" --pool-name '$pool_name'"
    cmd+=" --volume-name '$volume_name'"
    cmd+=" --subvolume-name '$subvolume_name'"
    cmd+=" --resource-group '$resource_group'"
    cmd+=" --parent-path '$parent_path'"
    
    if [ -n "$path" ]; then
        cmd+=" --path '$path'"
    else
        cmd+=" --path '/clones/$subvolume_name'"
    fi
    
    log "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        log "Subvolume clone '$subvolume_name' created successfully from parent '$parent_path'"
        show_subvolume "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group"
    else
        error "Failed to create subvolume clone '$subvolume_name'"
        return 1
    fi
}

# Function to update subvolume
update_subvolume() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local subvolume_name="$4"
    local resource_group="$5"
    local path="$6"
    local size="$7"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$subvolume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, subvolume name, and resource group are required"
        return 1
    fi
    
    info "Updating subvolume: $subvolume_name"
    
    local cmd="az netappfiles subvolume update"
    cmd+=" --account-name '$account_name'"
    cmd+=" --pool-name '$pool_name'"
    cmd+=" --volume-name '$volume_name'"
    cmd+=" --subvolume-name '$subvolume_name'"
    cmd+=" --resource-group '$resource_group'"
    
    if [ -n "$path" ]; then
        cmd+=" --path '$path'"
    fi
    
    if [ -n "$size" ]; then
        cmd+=" --size $size"
    fi
    
    log "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        log "Subvolume '$subvolume_name' updated successfully"
        show_subvolume "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group"
    else
        error "Failed to update subvolume '$subvolume_name'"
        return 1
    fi
}

# Function to show subvolume details
show_subvolume() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local subvolume_name="$4"
    local resource_group="$5"
    local output_format="${6:-table}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$subvolume_name" ] || [ -z "$resource_group" ]; then
        error "All parameters are required to show subvolume"
        return 1
    fi
    
    info "Getting subvolume details: $subvolume_name"
    
    az netappfiles subvolume show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --subvolume-name "$subvolume_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to show subvolume metadata
show_subvolume_metadata() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local subvolume_name="$4"
    local resource_group="$5"
    local output_format="${6:-table}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$subvolume_name" ] || [ -z "$resource_group" ]; then
        error "All parameters are required to show subvolume metadata"
        return 1
    fi
    
    info "Getting subvolume metadata: $subvolume_name"
    
    az netappfiles subvolume metadata show \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --subvolume-name "$subvolume_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to list all subvolumes in a volume
list_subvolumes() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local output_format="${5:-table}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Listing subvolumes for volume: $volume_name"
    
    az netappfiles subvolume list \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --output "$output_format"
}

# Function to delete subvolume
delete_subvolume() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local subvolume_name="$4"
    local resource_group="$5"
    local force="${6:-false}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$subvolume_name" ] || [ -z "$resource_group" ]; then
        error "All parameters are required to delete subvolume"
        return 1
    fi
    
    if [ "$force" != "true" ]; then
        read -p "Are you sure you want to delete subvolume '$subvolume_name'? (y/N): " confirmation
        if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
            warn "Subvolume deletion cancelled"
            return 0
        fi
    fi
    
    info "Deleting subvolume: $subvolume_name"
    
    az netappfiles subvolume delete \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --subvolume-name "$subvolume_name" \
        --resource-group "$resource_group" \
        --yes
    
    if [ $? -eq 0 ]; then
        log "Subvolume '$subvolume_name' deleted successfully"
    else
        error "Failed to delete subvolume '$subvolume_name'"
        return 1
    fi
}

# Function to create subvolume hierarchy
create_subvolume_hierarchy() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local hierarchy_file="$5"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ] || [ -z "$hierarchy_file" ]; then
        error "All parameters including hierarchy file are required"
        return 1
    fi
    
    if [ ! -f "$hierarchy_file" ]; then
        error "Hierarchy file not found: $hierarchy_file"
        return 1
    fi
    
    log "Creating subvolume hierarchy from file: $hierarchy_file"
    
    local success_count=0
    local error_count=0
    
    while IFS=',' read -r subvolume_name path size parent_path; do
        # Skip empty lines and comments
        [[ -z "$subvolume_name" || "$subvolume_name" =~ ^#.*$ ]] && continue
        
        info "Creating subvolume in hierarchy: $subvolume_name"
        
        if [ -n "$parent_path" ] && [ "$parent_path" != "null" ] && [ "$parent_path" != "" ]; then
            # Create as clone
            if create_subvolume_clone "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group" "$parent_path" "$path"; then
                ((success_count++))
            else
                ((error_count++))
                warn "Failed to create subvolume clone: $subvolume_name"
            fi
        else
            # Create as new subvolume
            if create_subvolume "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group" "$path" "$size"; then
                ((success_count++))
            else
                ((error_count++))
                warn "Failed to create subvolume: $subvolume_name"
            fi
        fi
        
        # Small delay to avoid throttling
        sleep 2
    done < "$hierarchy_file"
    
    log "Subvolume hierarchy creation completed: $success_count successful, $error_count failed"
}

# Function to monitor subvolume usage
monitor_subvolume_usage() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local threshold="${5:-80}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Monitoring subvolume usage (threshold: ${threshold}%)"
    
    # Get all subvolumes
    local subvolumes=$(az netappfiles subvolume list \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --output json)
    
    local subvolume_count=$(echo "$subvolumes" | jq length)
    
    echo -e "\n${BLUE}=== Subvolume Usage Monitor ===${NC}"
    echo "Volume: $volume_name"
    echo "Total Subvolumes: $subvolume_count"
    echo "Usage Threshold: ${threshold}%"
    
    if [ "$subvolume_count" -eq 0 ]; then
        warn "No subvolumes found in volume"
        return 0
    fi
    
    echo -e "\n${BLUE}=== Subvolume Details ===${NC}"
    printf "%-20s %-30s %-15s %-15s\n" "Subvolume" "Path" "Size (Bytes)" "Status"
    printf "%-20s %-30s %-15s %-15s\n" "---------" "----" "-----------" "------"
    
    echo "$subvolumes" | jq -r '.[] | "\(.name)|\(.path // "N/A")|\(.size // "N/A")|\(.provisioningState // "N/A")"' | while IFS='|' read -r name path size status; do
        printf "%-20s %-30s %-15s %-15s\n" "$name" "$path" "$size" "$status"
    done
}

# Function to export subvolume configuration
export_subvolume_config() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    local output_file="${5:-subvolume-config-$(date +%Y%m%d-%H%M%S).json}"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Exporting subvolume configuration to: $output_file"
    
    az netappfiles subvolume list \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --output json > "$output_file"
    
    if [ $? -eq 0 ]; then
        log "Subvolume configuration exported to '$output_file'"
        
        # Show summary
        local subvolume_count=$(jq length "$output_file")
        echo -e "\n${GREEN}=== Export Summary ===${NC}"
        echo "File: $output_file"
        echo "Subvolumes Exported: $subvolume_count"
        echo "Format: JSON"
    else
        error "Failed to export subvolume configuration"
        return 1
    fi
}

# Function to validate subvolume configuration
validate_subvolume_config() {
    local account_name="$1"
    local pool_name="$2"
    local volume_name="$3"
    local resource_group="$4"
    
    if [ -z "$account_name" ] || [ -z "$pool_name" ] || [ -z "$volume_name" ] || [ -z "$resource_group" ]; then
        error "Account name, pool name, volume name, and resource group are required"
        return 1
    fi
    
    info "Validating subvolume configuration for volume: $volume_name"
    
    # Get all subvolumes
    local subvolumes=$(az netappfiles subvolume list \
        --account-name "$account_name" \
        --pool-name "$pool_name" \
        --volume-name "$volume_name" \
        --resource-group "$resource_group" \
        --output json)
    
    local subvolume_count=$(echo "$subvolumes" | jq length)
    
    echo -e "\n${BLUE}=== Subvolume Configuration Validation ===${NC}"
    echo "Volume: $volume_name"
    echo "Total Subvolumes: $subvolume_count"
    
    if [ "$subvolume_count" -eq 0 ]; then
        warn "No subvolumes configured for this volume"
        return 0
    fi
    
    # Check for issues
    local warnings=0
    local errors=0
    
    # Check for failed provisioning states
    local failed_count=$(echo "$subvolumes" | jq -r '.[] | select(.provisioningState != "Succeeded") | .name' | wc -l)
    if [ "$failed_count" -gt 0 ]; then
        ((errors++))
        error "Found $failed_count subvolumes with failed provisioning state"
        echo "$subvolumes" | jq -r '.[] | select(.provisioningState != "Succeeded") | "  - \(.name): \(.provisioningState)"'
    fi
    
    # Check for duplicate paths
    local duplicate_paths=$(echo "$subvolumes" | jq -r '.[].path' | sort | uniq -d | wc -l)
    if [ "$duplicate_paths" -gt 0 ]; then
        ((warnings++))
        warn "Found duplicate paths in subvolumes"
    fi
    
    # Check for missing metadata
    echo -e "\n${BLUE}=== Metadata Validation ===${NC}"
    local metadata_issues=0
    
    echo "$subvolumes" | jq -r '.[].name' | while read -r subvolume_name; do
        local metadata=$(az netappfiles subvolume metadata show \
            --account-name "$account_name" \
            --pool-name "$pool_name" \
            --volume-name "$volume_name" \
            --subvolume-name "$subvolume_name" \
            --resource-group "$resource_group" \
            --output json 2>/dev/null)
        
        if [ -z "$metadata" ]; then
            warn "Missing metadata for subvolume: $subvolume_name"
            ((metadata_issues++))
        fi
    done
    
    # Summary
    echo -e "\n${BLUE}=== Validation Summary ===${NC}"
    echo "Errors: $errors"
    echo "Warnings: $warnings"
    
    if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
        log "All subvolume configuration validation checks passed"
        return 0
    else
        warn "Subvolume configuration validation completed with issues"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG [options]"
    echo "  create-clone --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG --parent-path PATH [options]"
    echo "  update --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG [options]"
    echo "  delete --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG [--force]"
    echo "  show --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG"
    echo "  metadata --account ACCOUNT --pool POOL --volume VOLUME --name NAME --rg RG"
    echo "  list --account ACCOUNT --pool POOL --volume VOLUME --rg RG"
    echo "  hierarchy --account ACCOUNT --pool POOL --volume VOLUME --rg RG --file FILE"
    echo "  monitor --account ACCOUNT --pool POOL --volume VOLUME --rg RG [--threshold PERCENT]"
    echo "  export --account ACCOUNT --pool POOL --volume VOLUME --rg RG [--output FILE]"
    echo "  validate --account ACCOUNT --pool POOL --volume VOLUME --rg RG"
    echo ""
    echo "Options:"
    echo "  --account ACCOUNT              NetApp account name"
    echo "  --pool POOL                    Capacity pool name"
    echo "  --volume VOLUME                Volume name"
    echo "  --name NAME                    Subvolume name"
    echo "  --rg, --resource-group RG      Resource group"
    echo "  --path PATH                    Subvolume path"
    echo "  --size SIZE                    Subvolume size in bytes"
    echo "  --parent-path PATH             Parent path for cloning"
    echo "  --file FILE                    Hierarchy configuration file"
    echo "  --output FILE                  Output file for export"
    echo "  --threshold PERCENT            Usage threshold percentage (default: 80)"
    echo "  --force                        Force deletion without confirmation"
    echo "  --format FORMAT                Output format (table, json, yaml, tsv)"
    echo ""
    echo "Hierarchy File Format (CSV):"
    echo "  subvolume_name,path,size,parent_path"
    echo "  app1,/app1,1073741824,"
    echo "  app1-clone,/app1-clone,,/app1"
    echo ""
    echo "Examples:"
    echo "  $0 create --account myAccount --pool myPool --volume myVolume --name app1 --rg myRG --path /app1 --size 1073741824"
    echo "  $0 create-clone --account myAccount --pool myPool --volume myVolume --name app1-clone --rg myRG --parent-path /app1"
    echo "  $0 hierarchy --account myAccount --pool myPool --volume myVolume --rg myRG --file subvolumes.csv"
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
    local subvolume_name=""
    local resource_group=""
    local path=""
    local size=""
    local parent_path=""
    local hierarchy_file=""
    local output_file=""
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
                subvolume_name="$2"
                shift 2
                ;;
            --rg|--resource-group)
                resource_group="$2"
                shift 2
                ;;
            --path)
                path="$2"
                shift 2
                ;;
            --size)
                size="$2"
                shift 2
                ;;
            --parent-path)
                parent_path="$2"
                shift 2
                ;;
            --file)
                hierarchy_file="$2"
                shift 2
                ;;
            --output)
                output_file="$2"
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
            create_subvolume "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group" "$path" "$size"
            ;;
        create-clone)
            create_subvolume_clone "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group" "$parent_path" "$path"
            ;;
        update)
            update_subvolume "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group" "$path" "$size"
            ;;
        delete)
            delete_subvolume "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group" "$force"
            ;;
        show)
            show_subvolume "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group" "$output_format"
            ;;
        metadata)
            show_subvolume_metadata "$account_name" "$pool_name" "$volume_name" "$subvolume_name" "$resource_group" "$output_format"
            ;;
        list)
            list_subvolumes "$account_name" "$pool_name" "$volume_name" "$resource_group" "$output_format"
            ;;
        hierarchy)
            create_subvolume_hierarchy "$account_name" "$pool_name" "$volume_name" "$resource_group" "$hierarchy_file"
            ;;
        monitor)
            monitor_subvolume_usage "$account_name" "$pool_name" "$volume_name" "$resource_group" "$threshold"
            ;;
        export)
            export_subvolume_config "$account_name" "$pool_name" "$volume_name" "$resource_group" "$output_file"
            ;;
        validate)
            validate_subvolume_config "$account_name" "$pool_name" "$volume_name" "$resource_group"
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
