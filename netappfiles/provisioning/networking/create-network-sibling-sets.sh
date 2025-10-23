#!/bin/bash
# Azure NetApp Files - Network Sibling Set Management
# Manage network sibling sets, network features, and networking configurations

set -e

# Configuration
SCRIPT_NAME="ANF Network Sibling Set Management"
LOG_FILE="anf-network-sibling-sets-$(date +%Y%m%d-%H%M%S).log"

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

# Function to query network sibling set
query_network_sibling_set() {
    local network_sibling_set_id="$1"
    local subnet_id="$2"
    local location="$3"
    
    if [ -z "$network_sibling_set_id" ] || [ -z "$subnet_id" ] || [ -z "$location" ]; then
        error "Network sibling set ID, subnet ID, and location are required"
        return 1
    fi
    
    info "Querying network sibling set: $network_sibling_set_id"
    
    az netappfiles query-network-sibling-set \
        --location "$location" \
        --network-sibling-set-id "$network_sibling_set_id" \
        --subnet-id "$subnet_id" \
        --output table
    
    if [ $? -eq 0 ]; then
        log "Network sibling set query completed successfully"
    else
        error "Failed to query network sibling set"
        return 1
    fi
}

# Function to update network sibling set
update_network_sibling_set() {
    local network_sibling_set_id="$1"
    local subnet_id="$2"
    local state_id="$3"
    local location="$4"
    local network_features="${5:-Standard}"
    local no_wait="${6:-false}"
    
    if [ -z "$network_sibling_set_id" ] || [ -z "$subnet_id" ] || [ -z "$state_id" ] || [ -z "$location" ]; then
        error "Network sibling set ID, subnet ID, state ID, and location are required"
        return 1
    fi
    
    info "Updating network sibling set: $network_sibling_set_id"
    
    local cmd="az netappfiles update-network-sibling-set"
    cmd+=" --location '$location'"
    cmd+=" --network-sibling-set-id '$network_sibling_set_id'"
    cmd+=" --subnet-id '$subnet_id'"
    cmd+=" --network-sibling-set-state-id '$state_id'"
    cmd+=" --network-features '$network_features'"
    
    if [ "$no_wait" = "true" ]; then
        cmd+=" --no-wait"
    fi
    
    log "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        log "Network sibling set updated successfully"
        
        if [ "$no_wait" != "true" ]; then
            # Query the updated sibling set
            query_network_sibling_set "$network_sibling_set_id" "$subnet_id" "$location"
        fi
    else
        error "Failed to update network sibling set"
        return 1
    fi
}

# Function to create Virtual Network for ANF
create_anf_vnet() {
    local vnet_name="$1"
    local resource_group="$2"
    local location="$3"
    local address_prefix="${4:-10.0.0.0/16}"
    
    if [ -z "$vnet_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "VNet name, resource group, and location are required"
        return 1
    fi
    
    info "Creating Virtual Network for ANF: $vnet_name"
    
    az network vnet create \
        --name "$vnet_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --address-prefixes "$address_prefix"
    
    if [ $? -eq 0 ]; then
        log "Virtual Network '$vnet_name' created successfully"
    else
        error "Failed to create Virtual Network '$vnet_name'"
        return 1
    fi
}

# Function to create delegated subnet for ANF
create_anf_subnet() {
    local subnet_name="$1"
    local vnet_name="$2"
    local resource_group="$3"
    local address_prefix="${4:-10.0.1.0/24}"
    
    if [ -z "$subnet_name" ] || [ -z "$vnet_name" ] || [ -z "$resource_group" ]; then
        error "Subnet name, VNet name, and resource group are required"
        return 1
    fi
    
    info "Creating delegated subnet for ANF: $subnet_name"
    
    az network vnet subnet create \
        --name "$subnet_name" \
        --vnet-name "$vnet_name" \
        --resource-group "$resource_group" \
        --address-prefixes "$address_prefix" \
        --delegations "Microsoft.NetApp/volumes"
    
    if [ $? -eq 0 ]; then
        log "Delegated subnet '$subnet_name' created successfully"
        
        # Get subnet ID
        local subnet_id=$(az network vnet subnet show \
            --name "$subnet_name" \
            --vnet-name "$vnet_name" \
            --resource-group "$resource_group" \
            --query id -o tsv)
        
        info "Subnet ID: $subnet_id"
        echo "$subnet_id"
    else
        error "Failed to create delegated subnet '$subnet_name'"
        return 1
    fi
}

# Function to create network security group for ANF
create_anf_nsg() {
    local nsg_name="$1"
    local resource_group="$2"
    local location="$3"
    
    if [ -z "$nsg_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "NSG name, resource group, and location are required"
        return 1
    fi
    
    info "Creating Network Security Group for ANF: $nsg_name"
    
    # Create NSG
    az network nsg create \
        --name "$nsg_name" \
        --resource-group "$resource_group" \
        --location "$location"
    
    if [ $? -eq 0 ]; then
        log "Network Security Group '$nsg_name' created successfully"
        
        # Add ANF-specific rules
        configure_anf_nsg_rules "$nsg_name" "$resource_group"
    else
        error "Failed to create Network Security Group '$nsg_name'"
        return 1
    fi
}

# Function to configure NSG rules for ANF
configure_anf_nsg_rules() {
    local nsg_name="$1"
    local resource_group="$2"
    
    if [ -z "$nsg_name" ] || [ -z "$resource_group" ]; then
        error "NSG name and resource group are required"
        return 1
    fi
    
    info "Configuring NSG rules for ANF: $nsg_name"
    
    # Allow NFS traffic (port 2049)
    az network nsg rule create \
        --nsg-name "$nsg_name" \
        --resource-group "$resource_group" \
        --name "AllowNFS" \
        --priority 1000 \
        --direction Inbound \
        --access Allow \
        --protocol Tcp \
        --source-address-prefixes "*" \
        --source-port-ranges "*" \
        --destination-address-prefixes "*" \
        --destination-port-ranges 2049
    
    # Allow SMB traffic (port 445)
    az network nsg rule create \
        --nsg-name "$nsg_name" \
        --resource-group "$resource_group" \
        --name "AllowSMB" \
        --priority 1010 \
        --direction Inbound \
        --access Allow \
        --protocol Tcp \
        --source-address-prefixes "*" \
        --source-port-ranges "*" \
        --destination-address-prefixes "*" \
        --destination-port-ranges 445
    
    # Allow RPC portmapper (port 111)
    az network nsg rule create \
        --nsg-name "$nsg_name" \
        --resource-group "$resource_group" \
        --name "AllowRPCPortmapper" \
        --priority 1020 \
        --direction Inbound \
        --access Allow \
        --protocol Tcp \
        --source-address-prefixes "*" \
        --source-port-ranges "*" \
        --destination-address-prefixes "*" \
        --destination-port-ranges 111
    
    # Allow UDP for NFS
    az network nsg rule create \
        --nsg-name "$nsg_name" \
        --resource-group "$resource_group" \
        --name "AllowNFSUDP" \
        --priority 1030 \
        --direction Inbound \
        --access Allow \
        --protocol Udp \
        --source-address-prefixes "*" \
        --source-port-ranges "*" \
        --destination-address-prefixes "*" \
        --destination-port-ranges 2049
    
    log "NSG rules configured for ANF traffic"
}

# Function to associate NSG with subnet
associate_nsg_with_subnet() {
    local subnet_name="$1"
    local vnet_name="$2"
    local nsg_name="$3"
    local resource_group="$4"
    
    if [ -z "$subnet_name" ] || [ -z "$vnet_name" ] || [ -z "$nsg_name" ] || [ -z "$resource_group" ]; then
        error "Subnet name, VNet name, NSG name, and resource group are required"
        return 1
    fi
    
    info "Associating NSG with subnet: $subnet_name"
    
    az network vnet subnet update \
        --name "$subnet_name" \
        --vnet-name "$vnet_name" \
        --resource-group "$resource_group" \
        --network-security-group "$nsg_name"
    
    if [ $? -eq 0 ]; then
        log "NSG '$nsg_name' associated with subnet '$subnet_name' successfully"
    else
        error "Failed to associate NSG with subnet"
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
    
    log "Executing: $cmd"
    eval "$cmd"
    
    if [ $? -eq 0 ]; then
        log "File path availability check completed"
    else
        error "Failed to check file path availability"
        return 1
    fi
}

# Function to create complete networking setup for ANF
create_anf_networking_setup() {
    local resource_group="$1"
    local location="$2"
    local vnet_name="${3:-anf-vnet}"
    local subnet_name="${4:-anf-subnet}"
    local nsg_name="${5:-anf-nsg}"
    local vnet_prefix="${6:-10.0.0.0/16}"
    local subnet_prefix="${7:-10.0.1.0/24}"
    
    if [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Resource group and location are required"
        return 1
    fi
    
    log "Creating complete ANF networking setup"
    
    # Step 1: Create Virtual Network
    create_anf_vnet "$vnet_name" "$resource_group" "$location" "$vnet_prefix"
    
    # Step 2: Create Network Security Group
    create_anf_nsg "$nsg_name" "$resource_group" "$location"
    
    # Step 3: Create delegated subnet
    local subnet_id=$(create_anf_subnet "$subnet_name" "$vnet_name" "$resource_group" "$subnet_prefix")
    
    if [ -z "$subnet_id" ]; then
        error "Failed to get subnet ID"
        return 1
    fi
    
    # Step 4: Associate NSG with subnet
    associate_nsg_with_subnet "$subnet_name" "$vnet_name" "$nsg_name" "$resource_group"
    
    log "Complete ANF networking setup completed successfully"
    
    # Display setup summary
    echo -e "\n${GREEN}=== ANF Networking Setup Summary ===${NC}"
    echo "Resource Group: $resource_group"
    echo "Location: $location"
    echo "Virtual Network: $vnet_name ($vnet_prefix)"
    echo "Subnet: $subnet_name ($subnet_prefix)"
    echo "Network Security Group: $nsg_name"
    echo "Subnet ID: $subnet_id"
    
    # Verify delegation
    verify_subnet_delegation "$subnet_name" "$vnet_name" "$resource_group"
}

# Function to verify subnet delegation
verify_subnet_delegation() {
    local subnet_name="$1"
    local vnet_name="$2"
    local resource_group="$3"
    
    if [ -z "$subnet_name" ] || [ -z "$vnet_name" ] || [ -z "$resource_group" ]; then
        error "Subnet name, VNet name, and resource group are required"
        return 1
    fi
    
    info "Verifying subnet delegation for ANF"
    
    local delegations=$(az network vnet subnet show \
        --name "$subnet_name" \
        --vnet-name "$vnet_name" \
        --resource-group "$resource_group" \
        --query "delegations[].serviceName" -o tsv)
    
    if [[ "$delegations" == *"Microsoft.NetApp/volumes"* ]]; then
        log "Subnet correctly delegated to Microsoft.NetApp/volumes"
    else
        error "Subnet is not properly delegated to Microsoft.NetApp/volumes"
        return 1
    fi
}

# Function to update network features for sibling set
update_network_features() {
    local network_sibling_set_id="$1"
    local subnet_id="$2"
    local state_id="$3"
    local location="$4"
    local network_features="$5"
    
    if [ -z "$network_sibling_set_id" ] || [ -z "$subnet_id" ] || [ -z "$state_id" ] || [ -z "$location" ] || [ -z "$network_features" ]; then
        error "All parameters are required for network features update"
        return 1
    fi
    
    case "$network_features" in
        "Basic"|"Standard")
            ;;
        *)
            error "Network features must be 'Basic' or 'Standard'"
            return 1
            ;;
    esac
    
    info "Updating network features to: $network_features"
    
    update_network_sibling_set "$network_sibling_set_id" "$subnet_id" "$state_id" "$location" "$network_features"
    
    if [ $? -eq 0 ]; then
        log "Network features updated to '$network_features' successfully"
    else
        error "Failed to update network features"
        return 1
    fi
}

# Function to get region network information
get_region_network_info() {
    local location="$1"
    
    if [ -z "$location" ]; then
        error "Location is required"
        return 1
    fi
    
    info "Getting region network information for: $location"
    
    az netappfiles resource region-info list \
        --location "$location" \
        --output table
    
    if [ $? -eq 0 ]; then
        log "Region network information retrieved successfully"
    else
        error "Failed to get region network information"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  query-sibling-set --sibling-set-id ID --subnet-id ID --location LOCATION"
    echo "  update-sibling-set --sibling-set-id ID --subnet-id ID --state-id ID --location LOCATION [options]"
    echo "  create-vnet --name NAME --rg RG --location LOCATION [--address-prefix PREFIX]"
    echo "  create-subnet --name NAME --vnet VNET --rg RG [--address-prefix PREFIX]"
    echo "  create-nsg --name NAME --rg RG --location LOCATION"
    echo "  associate-nsg --subnet SUBNET --vnet VNET --nsg NSG --rg RG"
    echo "  check-file-path --path PATH --subnet-id ID --location LOCATION [--zone ZONE]"
    echo "  setup-networking --rg RG --location LOCATION [options]"
    echo "  verify-delegation --subnet SUBNET --vnet VNET --rg RG"
    echo "  update-features --sibling-set-id ID --subnet-id ID --state-id ID --location LOCATION --features FEATURES"
    echo "  region-info --location LOCATION"
    echo ""
    echo "Options:"
    echo "  --sibling-set-id ID            Network sibling set ID"
    echo "  --subnet-id ID                 Subnet resource ID"
    echo "  --state-id ID                  Network sibling set state ID"
    echo "  --location LOCATION            Azure location"
    echo "  --features FEATURES            Network features (Basic/Standard)"
    echo "  --name NAME                    Resource name"
    echo "  --vnet VNET                    Virtual network name"
    echo "  --subnet SUBNET                Subnet name"
    echo "  --nsg NSG                      Network security group name"
    echo "  --rg, --resource-group RG      Resource group"
    echo "  --address-prefix PREFIX        Address prefix (CIDR)"
    echo "  --path PATH                    File path to check"
    echo "  --zone ZONE                    Availability zone"
    echo "  --no-wait                      Don't wait for operation completion"
    echo ""
    echo "Examples:"
    echo "  $0 setup-networking --rg myRG --location eastus"
    echo "  $0 update-features --sibling-set-id 12345 --subnet-id /subscriptions/.../subnets/anf-subnet --state-id 67890 --location eastus --features Standard"
    echo "  $0 check-file-path --path myvolume --subnet-id /subscriptions/.../subnets/anf-subnet --location eastus"
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
    local sibling_set_id=""
    local subnet_id=""
    local state_id=""
    local location=""
    local network_features=""
    local resource_name=""
    local vnet_name=""
    local subnet_name=""
    local nsg_name=""
    local resource_group=""
    local address_prefix=""
    local file_path=""
    local availability_zone=""
    local no_wait="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --sibling-set-id)
                sibling_set_id="$2"
                shift 2
                ;;
            --subnet-id)
                subnet_id="$2"
                shift 2
                ;;
            --state-id)
                state_id="$2"
                shift 2
                ;;
            --location)
                location="$2"
                shift 2
                ;;
            --features)
                network_features="$2"
                shift 2
                ;;
            --name)
                resource_name="$2"
                shift 2
                ;;
            --vnet)
                vnet_name="$2"
                shift 2
                ;;
            --subnet)
                subnet_name="$2"
                shift 2
                ;;
            --nsg)
                nsg_name="$2"
                shift 2
                ;;
            --rg|--resource-group)
                resource_group="$2"
                shift 2
                ;;
            --address-prefix)
                address_prefix="$2"
                shift 2
                ;;
            --path)
                file_path="$2"
                shift 2
                ;;
            --zone)
                availability_zone="$2"
                shift 2
                ;;
            --no-wait)
                no_wait="true"
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
        query-sibling-set)
            query_network_sibling_set "$sibling_set_id" "$subnet_id" "$location"
            ;;
        update-sibling-set)
            update_network_sibling_set "$sibling_set_id" "$subnet_id" "$state_id" "$location" "$network_features" "$no_wait"
            ;;
        create-vnet)
            create_anf_vnet "$resource_name" "$resource_group" "$location" "$address_prefix"
            ;;
        create-subnet)
            create_anf_subnet "$resource_name" "$vnet_name" "$resource_group" "$address_prefix"
            ;;
        create-nsg)
            create_anf_nsg "$resource_name" "$resource_group" "$location"
            ;;
        associate-nsg)
            associate_nsg_with_subnet "$subnet_name" "$vnet_name" "$nsg_name" "$resource_group"
            ;;
        check-file-path)
            check_file_path_availability "$file_path" "$subnet_id" "$location" "$availability_zone"
            ;;
        setup-networking)
            create_anf_networking_setup "$resource_group" "$location" "$vnet_name" "$subnet_name" "$nsg_name" "$address_prefix"
            ;;
        verify-delegation)
            verify_subnet_delegation "$subnet_name" "$vnet_name" "$resource_group"
            ;;
        update-features)
            update_network_features "$sibling_set_id" "$subnet_id" "$state_id" "$location" "$network_features"
            ;;
        region-info)
            get_region_network_info "$location"
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
