#!/bin/bash
# Azure NetApp Files - Encryption and Key Management
# Manage customer-managed keys, Key Vault integration, and encryption transitions

set -e

# Configuration
SCRIPT_NAME="ANF Encryption Management"
LOG_FILE="anf-encryption-$(date +%Y%m%d-%H%M%S).log"

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

# Function to create Key Vault for ANF encryption
create_key_vault() {
    local vault_name="$1"
    local resource_group="$2"
    local location="$3"
    local sku="${4:-standard}"
    
    if [ -z "$vault_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Vault name, resource group, and location are required"
        return 1
    fi
    
    info "Creating Key Vault for ANF encryption: $vault_name"
    
    # Create Key Vault with appropriate settings for ANF
    az keyvault create \
        --name "$vault_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --sku "$sku" \
        --enabled-for-disk-encryption true \
        --enabled-for-deployment true \
        --enabled-for-template-deployment true \
        --enable-purge-protection true \
        --enable-soft-delete true \
        --soft-delete-retention-days 90
    
    if [ $? -eq 0 ]; then
        log "Key Vault '$vault_name' created successfully"
        
        # Set access policy for current user
        local user_id=$(az ad signed-in-user show --query id -o tsv)
        az keyvault set-policy \
            --name "$vault_name" \
            --object-id "$user_id" \
            --key-permissions all \
            --secret-permissions all \
            --certificate-permissions all
            
        log "Access policy configured for Key Vault '$vault_name'"
    else
        error "Failed to create Key Vault '$vault_name'"
        return 1
    fi
}

# Function to create encryption key
create_encryption_key() {
    local vault_name="$1"
    local key_name="$2"
    local key_type="${3:-RSA}"
    local key_size="${4:-2048}"
    
    if [ -z "$vault_name" ] || [ -z "$key_name" ]; then
        error "Vault name and key name are required"
        return 1
    fi
    
    info "Creating encryption key: $key_name in vault: $vault_name"
    
    az keyvault key create \
        --vault-name "$vault_name" \
        --name "$key_name" \
        --kty "$key_type" \
        --size "$key_size" \
        --ops encrypt decrypt wrapKey unwrapKey
    
    if [ $? -eq 0 ]; then
        log "Encryption key '$key_name' created successfully"
        
        # Get key details
        local key_uri=$(az keyvault key show \
            --vault-name "$vault_name" \
            --name "$key_name" \
            --query key.kid -o tsv)
        
        info "Key URI: $key_uri"
    else
        error "Failed to create encryption key '$key_name'"
        return 1
    fi
}

# Function to create managed identity for encryption
create_encryption_identity() {
    local identity_name="$1"
    local resource_group="$2"
    local location="$3"
    
    if [ -z "$identity_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Identity name, resource group, and location are required"
        return 1
    fi
    
    info "Creating managed identity for encryption: $identity_name"
    
    az identity create \
        --name "$identity_name" \
        --resource-group "$resource_group" \
        --location "$location"
    
    if [ $? -eq 0 ]; then
        local principal_id=$(az identity show \
            --name "$identity_name" \
            --resource-group "$resource_group" \
            --query principalId -o tsv)
        
        local client_id=$(az identity show \
            --name "$identity_name" \
            --resource-group "$resource_group" \
            --query clientId -o tsv)
        
        log "Managed identity '$identity_name' created successfully"
        info "Principal ID: $principal_id"
        info "Client ID: $client_id"
        
        echo "$principal_id"
    else
        error "Failed to create managed identity '$identity_name'"
        return 1
    fi
}

# Function to configure Key Vault access for managed identity
configure_keyvault_access() {
    local vault_name="$1"
    local principal_id="$2"
    
    if [ -z "$vault_name" ] || [ -z "$principal_id" ]; then
        error "Vault name and principal ID are required"
        return 1
    fi
    
    info "Configuring Key Vault access for managed identity"
    
    az keyvault set-policy \
        --name "$vault_name" \
        --object-id "$principal_id" \
        --key-permissions get wrapKey unwrapKey
    
    if [ $? -eq 0 ]; then
        log "Key Vault access configured successfully"
    else
        error "Failed to configure Key Vault access"
        return 1
    fi
}

# Function to create NetApp account with customer-managed key encryption
create_encrypted_account() {
    local account_name="$1"
    local resource_group="$2"
    local location="$3"
    local vault_uri="$4"
    local key_name="$5"
    local identity_id="$6"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ] || [ -z "$location" ] || [ -z "$vault_uri" ] || [ -z "$key_name" ] || [ -z "$identity_id" ]; then
        error "All parameters are required for encrypted account creation"
        return 1
    fi
    
    info "Creating NetApp account with customer-managed key encryption: $account_name"
    
    # Extract key vault name from URI for key URI construction
    local vault_name=$(echo "$vault_uri" | sed 's|https://||' | sed 's|\.vault\.azure\.net||')
    local key_uri="${vault_uri}/keys/${key_name}"
    
    az netappfiles account create \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --encryption-key-source "Microsoft.KeyVault" \
        --encryption-identity "$identity_id" \
        --encryption-key-vault-uri "$vault_uri" \
        --encryption-key-name "$key_name"
    
    if [ $? -eq 0 ]; then
        log "Encrypted NetApp account '$account_name' created successfully"
        
        # Verify encryption configuration
        verify_encryption_configuration "$account_name" "$resource_group"
    else
        error "Failed to create encrypted NetApp account '$account_name'"
        return 1
    fi
}

# Function to transition account to customer-managed key
transition_to_cmk() {
    local account_name="$1"
    local resource_group="$2"
    local vault_uri="$3"
    local key_name="$4"
    local identity_id="$5"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ] || [ -z "$vault_uri" ] || [ -z "$key_name" ] || [ -z "$identity_id" ]; then
        error "All parameters are required for CMK transition"
        return 1
    fi
    
    info "Transitioning NetApp account to customer-managed key: $account_name"
    
    # First update the account with encryption properties
    az netappfiles account update \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --encryption-key-source "Microsoft.KeyVault" \
        --encryption-identity "$identity_id" \
        --encryption-key-vault-uri "$vault_uri" \
        --encryption-key-name "$key_name"
    
    if [ $? -eq 0 ]; then
        log "Account updated with encryption properties"
        
        # Execute the transition
        az netappfiles account transitiontocmk \
            --account-name "$account_name" \
            --resource-group "$resource_group"
        
        if [ $? -eq 0 ]; then
            log "Transition to customer-managed key completed successfully"
            
            # Wait for transition to complete
            info "Waiting for transition to complete..."
            az netappfiles account wait \
                --account-name "$account_name" \
                --resource-group "$resource_group" \
                --created
            
            verify_encryption_configuration "$account_name" "$resource_group"
        else
            error "Failed to execute CMK transition"
            return 1
        fi
    else
        error "Failed to update account with encryption properties"
        return 1
    fi
}

# Function to change Key Vault for existing encrypted account
change_key_vault() {
    local account_name="$1"
    local resource_group="$2"
    local new_vault_uri="$3"
    local new_key_name="$4"
    local new_identity_id="$5"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ] || [ -z "$new_vault_uri" ] || [ -z "$new_key_name" ] || [ -z "$new_identity_id" ]; then
        error "All parameters are required for Key Vault change"
        return 1
    fi
    
    info "Changing Key Vault for NetApp account: $account_name"
    
    az netappfiles account change-key-vault \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --encryption-key-vault-uri "$new_vault_uri" \
        --encryption-key-name "$new_key_name" \
        --encryption-identity "$new_identity_id"
    
    if [ $? -eq 0 ]; then
        log "Key Vault changed successfully for account '$account_name'"
        
        # Wait for the operation to complete
        info "Waiting for Key Vault change to complete..."
        az netappfiles account wait \
            --account-name "$account_name" \
            --resource-group "$resource_group" \
            --updated
        
        verify_encryption_configuration "$account_name" "$resource_group"
    else
        error "Failed to change Key Vault for account '$account_name'"
        return 1
    fi
}

# Function to renew encryption credentials
renew_credentials() {
    local account_name="$1"
    local resource_group="$2"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "Account name and resource group are required"
        return 1
    fi
    
    info "Renewing encryption credentials for account: $account_name"
    
    az netappfiles account renew-credentials \
        --account-name "$account_name" \
        --resource-group "$resource_group"
    
    if [ $? -eq 0 ]; then
        log "Encryption credentials renewed successfully"
        verify_encryption_configuration "$account_name" "$resource_group"
    else
        error "Failed to renew encryption credentials"
        return 1
    fi
}

# Function to get Key Vault status
get_key_vault_status() {
    local account_name="$1"
    local resource_group="$2"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "Account name and resource group are required"
        return 1
    fi
    
    info "Getting Key Vault status for account: $account_name"
    
    az netappfiles account get-key-vault-status \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --output table
}

# Function to verify encryption configuration
verify_encryption_configuration() {
    local account_name="$1"
    local resource_group="$2"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "Account name and resource group are required"
        return 1
    fi
    
    info "Verifying encryption configuration for account: $account_name"
    
    local account_data=$(az netappfiles account show \
        --account-name "$account_name" \
        --resource-group "$resource_group" \
        --output json)
    
    local key_source=$(echo "$account_data" | jq -r '.encryption.keySource // "Microsoft.NetApp"')
    local vault_uri=$(echo "$account_data" | jq -r '.encryption.keyVaultProperties.keyVaultUri // "N/A"')
    local key_name=$(echo "$account_data" | jq -r '.encryption.keyVaultProperties.keyName // "N/A"')
    local identity_id=$(echo "$account_data" | jq -r '.encryption.identity.userAssignedIdentity // "N/A"')
    
    echo -e "\n${BLUE}=== Encryption Configuration ===${NC}"
    echo "Account: $account_name"
    echo "Key Source: $key_source"
    echo "Key Vault URI: $vault_uri"
    echo "Key Name: $key_name"
    echo "Identity: $identity_id"
    
    if [ "$key_source" = "Microsoft.KeyVault" ]; then
        log "Account is using customer-managed key encryption"
        
        # Get detailed Key Vault status
        echo -e "\n${BLUE}=== Key Vault Status ===${NC}"
        get_key_vault_status "$account_name" "$resource_group"
    else
        warn "Account is using Microsoft-managed keys"
    fi
}

# Function to create complete encryption setup
create_encryption_setup() {
    local account_name="$1"
    local resource_group="$2"
    local location="$3"
    local vault_name="${4:-${account_name}-kv}"
    local key_name="${5:-${account_name}-key}"
    local identity_name="${6:-${account_name}-identity}"
    
    if [ -z "$account_name" ] || [ -z "$resource_group" ] || [ -z "$location" ]; then
        error "Account name, resource group, and location are required"
        return 1
    fi
    
    log "Creating complete encryption setup for account: $account_name"
    
    # Step 1: Create Key Vault
    create_key_vault "$vault_name" "$resource_group" "$location"
    
    # Step 2: Create encryption key
    create_encryption_key "$vault_name" "$key_name"
    
    # Step 3: Create managed identity
    local principal_id=$(create_encryption_identity "$identity_name" "$resource_group" "$location")
    
    if [ -z "$principal_id" ]; then
        error "Failed to get principal ID from managed identity"
        return 1
    fi
    
    # Step 4: Configure Key Vault access
    configure_keyvault_access "$vault_name" "$principal_id"
    
    # Step 5: Get necessary identifiers
    local vault_uri=$(az keyvault show --name "$vault_name" --query properties.vaultUri -o tsv)
    local identity_id=$(az identity show --name "$identity_name" --resource-group "$resource_group" --query id -o tsv)
    
    # Step 6: Create encrypted NetApp account
    create_encrypted_account "$account_name" "$resource_group" "$location" "$vault_uri" "$key_name" "$identity_id"
    
    log "Complete encryption setup completed for account: $account_name"
    
    # Display setup summary
    echo -e "\n${GREEN}=== Encryption Setup Summary ===${NC}"
    echo "NetApp Account: $account_name"
    echo "Key Vault: $vault_name"
    echo "Encryption Key: $key_name"
    echo "Managed Identity: $identity_name"
    echo "Key Vault URI: $vault_uri"
}

# Function to rotate encryption key
rotate_encryption_key() {
    local vault_name="$1"
    local key_name="$2"
    local account_name="$3"
    local resource_group="$4"
    
    if [ -z "$vault_name" ] || [ -z "$key_name" ] || [ -z "$account_name" ] || [ -z "$resource_group" ]; then
        error "All parameters are required for key rotation"
        return 1
    fi
    
    info "Rotating encryption key: $key_name"
    
    # Create new key version
    az keyvault key create \
        --vault-name "$vault_name" \
        --name "$key_name" \
        --ops encrypt decrypt wrapKey unwrapKey
    
    if [ $? -eq 0 ]; then
        log "New key version created successfully"
        
        # Renew credentials to pick up new key version
        renew_credentials "$account_name" "$resource_group"
        
        log "Key rotation completed successfully"
    else
        error "Failed to create new key version"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create-keyvault --name NAME --rg RG --location LOCATION [--sku SKU]"
    echo "  create-key --vault VAULT --name NAME [--type TYPE] [--size SIZE]"
    echo "  create-identity --name NAME --rg RG --location LOCATION"
    echo "  configure-access --vault VAULT --principal-id ID"
    echo "  create-encrypted --account ACCOUNT --rg RG --location LOCATION --vault-uri URI --key KEY --identity ID"
    echo "  transition-cmk --account ACCOUNT --rg RG --vault-uri URI --key KEY --identity ID"
    echo "  change-keyvault --account ACCOUNT --rg RG --vault-uri URI --key KEY --identity ID"
    echo "  renew-credentials --account ACCOUNT --rg RG"
    echo "  get-status --account ACCOUNT --rg RG"
    echo "  verify --account ACCOUNT --rg RG"
    echo "  setup --account ACCOUNT --rg RG --location LOCATION [options]"
    echo "  rotate-key --vault VAULT --key KEY --account ACCOUNT --rg RG"
    echo ""
    echo "Options:"
    echo "  --account ACCOUNT              NetApp account name"
    echo "  --name NAME                    Resource name"
    echo "  --vault VAULT                  Key Vault name"
    echo "  --key KEY                      Key name"
    echo "  --identity IDENTITY            Managed identity name"
    echo "  --rg, --resource-group RG      Resource group"
    echo "  --location LOCATION            Azure location"
    echo "  --vault-uri URI                Key Vault URI"
    echo "  --principal-id ID              Principal ID"
    echo "  --identity-id ID               Identity resource ID"
    echo "  --sku SKU                      Key Vault SKU (standard/premium)"
    echo "  --type TYPE                    Key type (RSA/EC)"
    echo "  --size SIZE                    Key size (2048/3072/4096)"
    echo ""
    echo "Examples:"
    echo "  $0 setup --account myAccount --rg myRG --location eastus"
    echo "  $0 transition-cmk --account myAccount --rg myRG --vault-uri https://myvault.vault.azure.net/ --key mykey --identity /subscriptions/.../identities/myidentity"
    echo "  $0 verify --account myAccount --rg myRG"
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
    local resource_name=""
    local vault_name=""
    local key_name=""
    local identity_name=""
    local resource_group=""
    local location=""
    local vault_uri=""
    local principal_id=""
    local identity_id=""
    local sku="standard"
    local key_type="RSA"
    local key_size="2048"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --account)
                account_name="$2"
                shift 2
                ;;
            --name)
                resource_name="$2"
                shift 2
                ;;
            --vault)
                vault_name="$2"
                shift 2
                ;;
            --key)
                key_name="$2"
                shift 2
                ;;
            --identity)
                identity_name="$2"
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
            --vault-uri)
                vault_uri="$2"
                shift 2
                ;;
            --principal-id)
                principal_id="$2"
                shift 2
                ;;
            --identity-id)
                identity_id="$2"
                shift 2
                ;;
            --sku)
                sku="$2"
                shift 2
                ;;
            --type)
                key_type="$2"
                shift 2
                ;;
            --size)
                key_size="$2"
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
        create-keyvault)
            create_key_vault "$resource_name" "$resource_group" "$location" "$sku"
            ;;
        create-key)
            create_encryption_key "$vault_name" "$resource_name" "$key_type" "$key_size"
            ;;
        create-identity)
            create_encryption_identity "$resource_name" "$resource_group" "$location"
            ;;
        configure-access)
            configure_keyvault_access "$vault_name" "$principal_id"
            ;;
        create-encrypted)
            create_encrypted_account "$account_name" "$resource_group" "$location" "$vault_uri" "$key_name" "$identity_id"
            ;;
        transition-cmk)
            transition_to_cmk "$account_name" "$resource_group" "$vault_uri" "$key_name" "$identity_id"
            ;;
        change-keyvault)
            change_key_vault "$account_name" "$resource_group" "$vault_uri" "$key_name" "$identity_id"
            ;;
        renew-credentials)
            renew_credentials "$account_name" "$resource_group"
            ;;
        get-status)
            get_key_vault_status "$account_name" "$resource_group"
            ;;
        verify)
            verify_encryption_configuration "$account_name" "$resource_group"
            ;;
        setup)
            create_encryption_setup "$account_name" "$resource_group" "$location" "$vault_name" "$key_name" "$identity_name"
            ;;
        rotate-key)
            rotate_encryption_key "$vault_name" "$key_name" "$account_name" "$resource_group"
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
