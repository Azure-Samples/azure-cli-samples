#!/bin/bash
# Azure NetApp Files - Active Directory Integration
# Create and manage Active Directory connections for SMB volumes

set -e

# Configuration
SCRIPT_NAME="ANF Active Directory Setup"
LOG_FILE="anf-ad-setup-$(date +%Y%m%d-%H%M%S).log"

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

# Function to create Active Directory connection
create_ad_connection() {
    local account_name="$1"
    local resource_group="$2"
    local location="$3"
    local domain="$4"
    local username="$5"
    local password="$6"
    local dns_servers="$7"
    local smb_server_name="$8"
    local organizational_unit="$9"
    local kdc_ip="${10}"
    local ad_name="${11:-ActiveDirectory}"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ] || [ -z "$location" ] || [ -z "$domain" ] || [ -z "$username" ] || [ -z "$password" ] || [ -z "$dns_servers" ]; then
        error "Account name, resource group, location, domain, username, password, and DNS servers are required"
        return 1
    fi
    
    log "Creating Active Directory connection for NetApp account: $account_name"
    
    # Validate password complexity
    if [ ${#password} -lt 8 ]; then
        error "Password must be at least 8 characters long"
        return 1
    fi
    
    # Build the create command
    local create_cmd="az netappfiles account ad create"
    create_cmd="$create_cmd --account-name \"$account_name\""
    create_cmd="$create_cmd --resource-group \"$resource_group\""
    create_cmd="$create_cmd --location \"$location\""
    create_cmd="$create_cmd --domain \"$domain\""
    create_cmd="$create_cmd --username \"$username\""
    create_cmd="$create_cmd --password \"$password\""
    create_cmd="$create_cmd --dns \"$dns_servers\""
    create_cmd="$create_cmd --active-directory-name \"$ad_name\""
    
    if [ ! -z "$smb_server_name" ]; then
        create_cmd="$create_cmd --smb-server-name \"$smb_server_name\""
        log "Using SMB server name: $smb_server_name"
    fi
    
    if [ ! -z "$organizational_unit" ]; then
        create_cmd="$create_cmd --organizational-unit \"$organizational_unit\""
        log "Using organizational unit: $organizational_unit"
    fi
    
    if [ ! -z "$kdc_ip" ]; then
        create_cmd="$create_cmd --kdc-ip \"$kdc_ip\""
        log "Using KDC IP: $kdc_ip"
    fi
    
    info "Executing: $create_cmd"
    eval "$create_cmd"
    
    log "Active Directory connection '$ad_name' created successfully"
}

# Function to create AD connection with LDAP signing
create_ad_with_ldap() {
    local account_name="$1"
    local resource_group="$2"
    local location="$3"
    local domain="$4"
    local username="$5"
    local password="$6"
    local dns_servers="$7"
    local ldap_signing="$8"
    local security_operators="$9"
    local ad_name="${10:-ActiveDirectoryLDAP}"
    
    log "Creating Active Directory connection with LDAP signing enabled"
    
    az netappfiles account ad create \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --domain "$domain" \
        --username "$username" \
        --password "$password" \
        --dns "$dns_servers" \
        --active-directory-name "$ad_name" \
        --ldap-signing "$ldap_signing" \
        --security-operators "$security_operators" \
        --allow-local-nfs-users-with-ldap true
    
    log "Active Directory connection with LDAP '$ad_name' created successfully"
}

# Function to update AD connection
update_ad_connection() {
    local account_name="$1"
    local resource_group="$2"
    local ad_name="$3"
    local username="$4"
    local password="$5"
    local dns_servers="$6"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ] || [ -z "$ad_name" ]; then
        error "Account name, resource group, and AD name are required"
        return 1
    fi
    
    log "Updating Active Directory connection: $ad_name"
    
    local update_cmd="az netappfiles account ad update"
    update_cmd="$update_cmd --account-name \"$account_name\""
    update_cmd="$update_cmd --resource-group \"$resource_group\""
    update_cmd="$update_cmd --active-directory-name \"$ad_name\""
    
    if [ ! -z "$username" ]; then
        update_cmd="$update_cmd --username \"$username\""
    fi
    
    if [ ! -z "$password" ]; then
        update_cmd="$update_cmd --password \"$password\""
    fi
    
    if [ ! -z "$dns_servers" ]; then
        update_cmd="$update_cmd --dns \"$dns_servers\""
    fi
    
    eval "$update_cmd"
    log "Active Directory connection '$ad_name' updated successfully"
}

# Function to test AD connection
test_ad_connection() {
    local account_name="$1"
    local resource_group="$2"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "Account name and resource group are required"
        return 1
    fi
    
    log "Testing Active Directory connectivity for account: $account_name"
    
    # List AD connections
    info "Current Active Directory connections:"
    az netappfiles account ad list \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --query "[].{Name:activeDirectoryName,Domain:domain,Status:status,DNS:dns}" \
        --output table
    
    # Show detailed AD connection info
    local ad_connections=$(az netappfiles account ad list \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --query "[].activeDirectoryName" \
        --output tsv)
    
    for ad_name in $ad_connections; do
        info "Detailed information for AD connection: $ad_name"
        az netappfiles account ad show \
            --account-name "$account_name" \
            --resource-group "$resource_group" \
            --active-directory-name "$ad_name" \
            --output json
    done
}

# Function to delete AD connection
delete_ad_connection() {
    local account_name="$1"
    local resource_group="$2"
    local ad_name="$3"
    local force_delete="$4"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ] || [ -z "$ad_name" ]; then
        error "Account name, resource group, and AD name are required"
        return 1
    fi
    
    if [ "$force_delete" != "true" ]; then
        warn "This will delete the Active Directory connection: $ad_name"
        warn "This may affect SMB volumes using this AD connection!"
        read -p "Are you sure you want to delete this AD connection? (y/N): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "AD connection deletion cancelled"
            return 0
        fi
    fi
    
    log "Deleting Active Directory connection: $ad_name"
    
    az netappfiles account ad delete \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --active-directory-name "$ad_name"
    
    log "Active Directory connection '$ad_name' deleted successfully"
}

# Function to create complete AD setup for SMB
create_smb_ready_setup() {
    local account_name="$1"
    local resource_group="$2"
    local location="$3"
    local domain="$4"
    local username="$5"
    local password="$6"
    local dns_servers="$7"
    local computer_name_prefix="$8"
    
    if [ -z "$computer_name_prefix" ]; then
        computer_name_prefix="ANFSMB"
    fi
    
    log "Creating complete SMB-ready Active Directory setup"
    
    # Generate SMB server name
    local smb_server_name="${computer_name_prefix}$(date +%Y%m%d)"
    
    # Create AD connection optimized for SMB
    az netappfiles account ad create \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --domain "$domain" \
        --username "$username" \
        --password "$password" \
        --dns "$dns_servers" \
        --smb-server-name "$smb_server_name" \
        --active-directory-name "SMBActiveDirectory" \
        --encrypt-dc-connections true \
        --aes-encryption true
    
    log "SMB-ready Active Directory setup completed"
    log "SMB Server Name: $smb_server_name"
    
    # Verify the setup
    info "Verifying AD connection:"
    az netappfiles account ad show \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --active-directory-name "SMBActiveDirectory" \
        --query "{Name:activeDirectoryName,Domain:domain,SMBServerName:smbServerName,Status:status}" \
        --output table
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create --account ACCOUNT --rg RG --location LOCATION --domain DOMAIN --username USER --password PASS --dns DNS [options]"
    echo "  create-ldap --account ACCOUNT --rg RG --location LOCATION --domain DOMAIN --username USER --password PASS --dns DNS --ldap-signing BOOL [options]"
    echo "  create-smb --account ACCOUNT --rg RG --location LOCATION --domain DOMAIN --username USER --password PASS --dns DNS [--prefix PREFIX]"
    echo "  update --account ACCOUNT --rg RG --ad-name AD_NAME [options]"
    echo "  test --account ACCOUNT --rg RG"
    echo "  delete --account ACCOUNT --rg RG --ad-name AD_NAME [--force]"
    echo ""
    echo "Options:"
    echo "  --account ACCOUNT              NetApp account name"
    echo "  --rg RG                       Resource group"
    echo "  --location LOCATION           Azure location"
    echo "  --domain DOMAIN               Active Directory domain (e.g., company.com)"
    echo "  --username USER               Domain user with permissions to join computers"
    echo "  --password PASS               Domain user password"
    echo "  --dns DNS                     DNS servers (comma-separated)"
    echo "  --smb-server-name NAME        SMB server name (computer account)"
    echo "  --ou OU                       Organizational Unit path"
    echo "  --kdc-ip IP                   Key Distribution Center IP"
    echo "  --ad-name NAME                Active Directory connection name"
    echo "  --ldap-signing BOOL           Enable LDAP signing (true/false)"
    echo "  --security-operators USERS   Security operators (comma-separated)"
    echo "  --prefix PREFIX               Computer name prefix for SMB setup"
    echo "  --force                       Skip confirmation prompts"
    echo ""
    echo "Examples:"
    echo "  # Basic AD connection"
    echo "  $0 create --account myAccount --rg myRG --location \"East US\" --domain \"company.com\" --username \"admin@company.com\" --password \"SecurePass123\" --dns \"10.0.0.4,10.0.0.5\""
    echo ""
    echo "  # SMB-optimized setup"
    echo "  $0 create-smb --account myAccount --rg myRG --location \"East US\" --domain \"company.com\" --username \"admin@company.com\" --password \"SecurePass123\" --dns \"10.0.0.4,10.0.0.5\" --prefix \"PRODSMB\""
    echo ""
    echo "  # LDAP-enabled connection"
    echo "  $0 create-ldap --account myAccount --rg myRG --location \"East US\" --domain \"company.com\" --username \"admin@company.com\" --password \"SecurePass123\" --dns \"10.0.0.4,10.0.0.5\" --ldap-signing true"
    echo ""
    echo "  # Test connectivity"
    echo "  $0 test --account myAccount --rg myRG"
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
    local resource_group=""
    local location=""
    local domain=""
    local username=""
    local password=""
    local dns_servers=""
    local smb_server_name=""
    local organizational_unit=""
    local kdc_ip=""
    local ad_name=""
    local ldap_signing="false"
    local security_operators=""
    local computer_prefix=""
    local force_delete="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --account)
                account_name="$2"
                shift 2
                ;;
            --rg)
                resource_group="$2"
                shift 2
                ;;
            --location)
                location="$2"
                shift 2
                ;;
            --domain)
                domain="$2"
                shift 2
                ;;
            --username)
                username="$2"
                shift 2
                ;;
            --password)
                password="$2"
                shift 2
                ;;
            --dns)
                dns_servers="$2"
                shift 2
                ;;
            --smb-server-name)
                smb_server_name="$2"
                shift 2
                ;;
            --ou)
                organizational_unit="$2"
                shift 2
                ;;
            --kdc-ip)
                kdc_ip="$2"
                shift 2
                ;;
            --ad-name)
                ad_name="$2"
                shift 2
                ;;
            --ldap-signing)
                ldap_signing="$2"
                shift 2
                ;;
            --security-operators)
                security_operators="$2"
                shift 2
                ;;
            --prefix)
                computer_prefix="$2"
                shift 2
                ;;
            --force)
                force_delete="true"
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
        create)
            create_ad_connection "$account_name" "$resource_group" "$location" "$domain" "$username" "$password" "$dns_servers" "$smb_server_name" "$organizational_unit" "$kdc_ip" "$ad_name"
            ;;
        create-ldap)
            create_ad_with_ldap "$account_name" "$resource_group" "$location" "$domain" "$username" "$password" "$dns_servers" "$ldap_signing" "$security_operators" "$ad_name"
            ;;
        create-smb)
            create_smb_ready_setup "$account_name" "$resource_group" "$location" "$domain" "$username" "$password" "$dns_servers" "$computer_prefix"
            ;;
        update)
            update_ad_connection "$account_name" "$resource_group" "$ad_name" "$username" "$password" "$dns_servers"
            ;;
        test)
            test_ad_connection "$account_name" "$resource_group"
            ;;
        delete)
            delete_ad_connection "$account_name" "$resource_group" "$ad_name" "$force_delete"
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
