#!/usr/bin/env bash
ADE_SCRIPT_VERSION=1.0

function print_help()
{
cat << EOM 
adeprereq.sh sets up key vault prerequisites for Azure Disk Encryption using Azure CLI 

Usage
~~~~~

adeprereq.sh [options]


Options
~~~~~~~

-h, --help 
Displays this help text. 

--ade-prefix <prefix>
Optional - this naming prefix will be used when auto-generating any missing components such as a resource group, keyvault, etc. to make identification easier.  If this is omitted the prefix 'ade' will be used. 

--ade-subscription-id <subid>
Optional - Subscription ID that will own the KeyVault and target VM(s). If not specified, the currently logged in default subscription will be used. 

--ade-location <location>
Optional - Regional datacenter location of the KeyVault and target VM(s).  Make sure the KeyVault and VM(s) to be encrypted are in the same regional location.  If not specified, the first result in the list of locations available in the active subscription will be used as the default location. For more information on Azure regions, see https://azure.microsoft.com/en-us/regions/ . 

---ade-rg-name <resourcegroupname>
Optional - Name of the resource group the KeyVault and target VM(s) belong to.  A new resource group with this name will be created if it does not already exist. If this option is not specified, a resource group with a unique random name will be created and used.

--ade-kv-name <keyvaultname>
Optional - Name of the KeyVault in which encryption keys are to be placed.  A new KeyVault with this name will be created if it does not already exist. If this option is not specified, a KeyVault with a unique random name will be created and used.

--ade-kek-name <kekname>
Optional - this specifies the name of a key encryption key in KeyVault if a key encryptino key is to be used.  A new key with this name will be created if one doesn't exist. 

--aad 
Optional - Create AAD application prerequisites.  This option will expose the client secret to the operator via standard output and persist it within the local file.  In environments where this is not acceptable, the steps to create AAD resources should be done outside of this script.

--ade-adapp-name <appname>
Optional - Name of the AAD application that will be used to write secrets to KeyVault. A new application with this name and a new corresponding client secret will be created if one doesn't exist. If the app already exists, the --ade-adapp-secret must also be specified. If this option is not specified, a new Azure Active Directory application with a unique name and client secret will be created and used.

--ade-adapp-secret <clientsecret>
Optional - Client secret to use for a new AD application.  This is an optional parameter that can be used if a specific client secret is desired when creating a new ad application.  If not specified, a new random client secret will be created during ad application creation. 

--ade-adapp-cert-name 
Name that the self-signed certificate to be used for encryption is referred to in keyvault. If not specified, a new name will be created for the certificate. When the thumbprint of this certificate is provided to the enable encryption command, and the certificate already resides on the VM, encryption can be enabled by certificate thumbprint instead of having to pass a client secret. 

--ade-log-dir <dir>
Optional - this specifies the full path to a directory to be used to log intermediate JSON files.  If not specified, a log dir will be created using a unique name in the current directory.

Notes
~~~~~

This script requires the Azure CLI and jq (for parsing JSON output of CLI commands) to be installed prior to execution.

A powershell script with similar functionality is available at https://raw.githubusercontent.com/Azure/azure-powershell/dev/src/ResourceManager/Compute/Commands.Compute/Extension/AzureDiskEncryption/Scripts/AzureDiskEncryptionPreRequisiteSetup.ps1 
EOM

exit
}

# parse options 
options=$@
arguments=($options)
index=0
for argument in $options
  do
    i=$(( $i + 1 ))
    case $argument in
	-h) ;&
	--help) print_help;;
    --aad) ADE_AAD=true;;
	--ade-rg-name) ADE_RG_NAME="${arguments[i]}";;
	--ade-kv-name) ADE_KV_NAME="${arguments[i]}";;
	--ade-location) ADE_LOCATION="${arguments[i]}";;
	--ade-adapp-name) ADE_ADAPP_NAME="${arguments[i]}";;
	--ade-adapp-cert-name) ADE_ADAPP_CERT_NAME="${arguments[i]}";;
	--ade-adapp-secret) ADE_ADAPP_SECRET="${arguments[i]}";;
	--ade-subscription-id) ADE_SUBSCRIPTION_ID="${arguments[i]}";;
	--ade-kek-name) ADE_KEK_NAME="${arguments[i]}";;
	--ade-prefix) ADE_PREFIX="${arguments[i]}";;
	--ade-log-dir) ADE_LOG_DIR="${arguments[i]}";;
    esac
  done

# make sure azure cli is installed
if ! [ -x "$(command -v az)" ]; then
  echo 'Error: Azure CLI 2.0 is not installed.  See: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli' >&2
  exit 1
fi

# make sure azure cli is logged in
if az account show | grep -m 1 "login"; then
  echo 'Error: Azure CLI is not logged in.  Please run the login command [az login].'
  exit 1
fi

# make sure jq is installed (sudo apt-get install jq)
if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq package is not installed. On Ubuntu use "sudo apt-get install jq" or for other options see: https://stedolan.github.io/jq/download/' >&2
  exit 1
fi

echo "- Azure Disk Encryption Prerequisites Script [version $ADE_SCRIPT_VERSION]"

# initialize script variables
ADE_UID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 4 | head -n 1)
ADE_LOG_SUFFIX=".json"
if [ -z "$ADE_PREFIX" ]; then 
	ADE_PREFIX="ade";
fi

if [ -z "$ADE_LOG_DIR" ]; then 
	ADE_LOG_DIR=$ADE_PREFIX$ADE_UID
fi

if [ ! -d "$ADE_LOG_DIR" ]; then 
	mkdir $ADE_LOG_DIR
fi

if [ -z "$ADE_SUBSCRIPTION_ID" ]; then 
	ADE_SUBSCRIPTION_ID="`az account show | jq -r '.id'`"
fi

if [ -z "$ADE_LOCATION" ]; then
	az account list-locations > $ADE_LOG_DIR/locations.json
	ADE_LOCATION="$(jq -r '.[0] | .name' $ADE_LOG_DIR/locations.json)"
fi 	
echo "- Location: $ADE_LOCATION"

# initialize resource group name variable
if [ -z "$ADE_RG_NAME" ]; then 
	ADE_RG_SUFFIX="rg"
	ADE_RG_NAME=$ADE_PREFIX$ADE_UID$ADE_RG_SUFFIX
fi

# create resource group if needed
az group create --name ${ADE_RG_NAME} --location ${ADE_LOCATION}  > "$ADE_LOG_DIR/rg_create.json" 2>&1
echo "- Resource group: $ADE_RG_NAME"

# KV name 
if [ -z "$ADE_KV_NAME" ]; then 
	ADE_KV_SUFFIX="kv"
	ADE_KV_NAME=$ADE_PREFIX$ADE_UID$ADE_KV_SUFFIX
fi 

# KV key encryption key name
if [ -z "$ADE_KEK_NAME" ]; then 
	ADE_KEK_SUFFIX="kek"
	ADE_KEK_NAME=$ADE_PREFIX$ADE_UID$ADE_KEK_SUFFIX 
fi

# create keyvault and set policy (premium sku offers HSM support)
az keyvault create --name ${ADE_KV_NAME} --resource-group ${ADE_RG_NAME} --location ${ADE_LOCATION} --sku premium > "$ADE_LOG_DIR/kv_create.json" 2>&1
echo "- Key vault: $ADE_KV_NAME"
ADE_KV_URI="`az keyvault show --name ${ADE_KV_NAME} --resource-group ${ADE_RG_NAME} | jq -r '.properties.vaultUri'`"
ADE_KV_ID="`az keyvault show --name ${ADE_KV_NAME} --resource-group ${ADE_RG_NAME} | jq -r '.id'`"
az keyvault update --name "${ADE_KV_NAME}" --resource-group "${ADE_RG_NAME}" --enabled-for-deployment true --enabled-for-disk-encryption true > "$ADE_LOG_DIR/kv_policy_update.json" 2>&1
echo "- Key vault policy enabled for deployment and disk encryption"

# create key encryption key
az keyvault key create --vault-name ${ADE_KV_NAME} --name ${ADE_KEK_NAME} --protection HSM  > "$ADE_LOG_DIR/kek_create.json" 2>&1
ADE_KEK_ID="${ADE_KV_ID}"
ADE_KEK_URI="`az keyvault key show --name ${ADE_KEK_NAME} --vault-name ${ADE_KV_NAME} | jq -r '.key.kid'`"
echo "- Key encryption key: $ADE_KEK_NAME" 

# generate corresponding AD application resources if requested
if [ "$ADE_AAD" = true ]; then    
    # AD application name
    if [ -z "$ADE_ADAPP_NAME" ]; then 
        ADE_ADAPP_SUFFIX="adapp"
        ADE_ADAPP_NAME="$ADE_PREFIX$ADE_UID$ADE_ADAPP_SUFFIX"
    fi

    # AD application URI
    if [ -z "$ADE_ADAPP_URI" ]; then 
        ADE_ADAPP_URI="https://localhost/${ADE_ADAPP_NAME}" 
    fi

    # AD application client secret 
    if [ -z "$ADE_ADAPP_SECRET" ]; then 
        ADE_ADAPP_SECRET="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
    fi

    # create ad application
    az ad app create --display-name $ADE_ADAPP_NAME --homepage $ADE_ADAPP_URI --identifier-uris $ADE_ADAPP_URI --password $ADE_ADAPP_SECRET > "$ADE_LOG_DIR/adapp.json" 2>&1
    ADE_ADSP_APPID="`az ad app list --display-name ${ADE_ADAPP_NAME} | jq -r '.[0] | .appId'`"
    echo "- AD application created: $ADE_ADAPP_NAME"

    # create service principal for ad application
    az ad sp create --id "${ADE_ADSP_APPID}" > "$ADE_LOG_DIR/adapsp.json" 2>&1
    ADE_ADSP_OID="`az ad sp list --display-name ${ADE_ADAPP_NAME} | jq -r '.[0] | .objectId'`"
    echo "- AD application service principal created"

    # create role assignment for ad app
    echo "- AD application role assignment starting, please wait..."
    # (retry until AD SP OID is visible in directory or time threshold is exceeded)
    SLEEP_CYCLES=0
    MAX_SLEEP=8
    until az role assignment create --assignee $ADE_ADSP_OID --role Reader --scope "/subscriptions/${ADE_SUBSCRIPTION_ID}/" > "$ADE_LOG_DIR/role_create.json" 2>&1 || [ $SLEEP_CYCLES -eq $MAX_SLEEP ]; do
    sleep 15
    (( SLEEP_CYCLES++ ))
    done
    if [ $SLEEP_CYCLES -eq $MAX_SLEEP ]
    then
        echo "- role assignment creation failed, timeout threshold exceeded"
        exit 1
    fi
    echo "- AD application role assignment created"

    az keyvault set-policy --name "${ADE_KV_NAME}" --resource-group "${ADE_RG_NAME}" --spn "${ADE_ADSP_APPID}" --key-permissions "wrapKey" --secret-permissions "set" > "$ADE_LOG_DIR/kv_policy_set.json" 2>&1
    az keyvault update --name "${ADE_KV_NAME}" --resource-group "${ADE_RG_NAME}" --enabled-for-deployment true --enabled-for-disk-encryption true > "$ADE_LOG_DIR/kv_policy_update.json" 2>&1
    echo "- AD application key vault policy set and updated"

    echo "- AD application client certificate creation starting, please wait..."
    # AD application client certificate
    if [ -z "$ADE_ADAPP_CERT_NAME" ]; then
    	ADE_CERT_SUFFIX="cert"
    	ADE_ADAPP_CERT_NAME=$ADE_PREFIX$ADE_UID$ADE_CERT_SUFFIX
    fi

    # create certificate using default policy if needed
    if ! az keyvault certificate show --vault-name $ADE_KV_NAME --name $ADE_ADAPP_CERT_NAME > "$ADE_LOG_DIR/cert_show_$ADE_ADAPP_CERT_NAME$ADE_LOG_SUFFIX" 2>&1; then
        az keyvault certificate create --vault-name $ADE_KV_NAME -n $ADE_ADAPP_CERT_NAME \-p "$(az keyvault certificate get-default-policy)" >> "$ADE_LOG_DIR/cert_create_$ADE_ADAPP_CERT_NAME$ADE_LOG_SUFFIX" 2>&1
    fi

    # wait for self signed certificate to be created  
    SLEEP_CYCLES=0
    MAX_SLEEP=12
    az keyvault certificate show --vault-name $ADE_KV_NAME --name $ADE_ADAPP_CERT_NAME > "$ADE_LOG_DIR/cert_show_$ADE_ADAPP_CERT_NAME$ADE_LOG_SUFFIX" 2>&1
    until jq -e '.x509ThumbprintHex' "$ADE_LOG_DIR/cert_show_$ADE_ADAPP_CERT_NAME$ADE_LOG_SUFFIX" > /dev/null 2>&1
    do
        sleep 10
        (( SLEEP_CYCLES++ ))
        az keyvault certificate show --vault-name $ADE_KV_NAME --name $ADE_ADAPP_CERT_NAME > "$ADE_LOG_DIR/cert_show_$ADE_ADAPP_CERT_NAME$ADE_LOG_SUFFIX" 2>&1
        if [ $SLEEP_CYCLES -eq $MAX_SLEEP ]
        then
            echo "- AD application self-signed certificate creation failed, timeout threshold exceeded"
            exit 1
        fi
    done
    ADE_KV_CERT_THUMB=$(jq -r '.x509ThumbprintHex' $ADE_LOG_DIR/cert_show_$ADE_ADAPP_CERT_NAME$ADE_LOG_SUFFIX )

    # append the self-signed certificate to the service principal's list of valid credentials
    az ad sp credential reset --name $ADE_ADAPP_URI --append --cert $ADE_ADAPP_CERT_NAME --keyvault $ADE_KV_NAME --json > $ADE_LOG_DIR/$ADE_KV_NAME$ADE_CERT_THUMB$ADE_LOG_SUFFIX 2>&1
    echo "- AD application client certificate created"
    # get the keyvault certificate secret id for later use in adding that certificate to the vm 
    ADE_KV_CERT_SID=$(jq -r '.sid' $ADE_LOG_DIR/cert_show_$ADE_ADAPP_CERT_NAME$ADE_LOG_SUFFIX )

fi 

# save values to log folder for future reference ("source ade_env.sh") 
compgen -v | grep ADE_ | while read var; do printf "%s=%q\n" "$var" "${!var}"; done > $ADE_LOG_DIR/ade_env.sh
echo "- ADE environment variables saved to local file: $ADE_LOG_DIR/ade_env.sh"

echo "- The following resources may be used to enable disk encryption:"
echo 
echo "ADE_SUBSCRIPTION_ID=$ADE_SUBSCRIPTION_ID"
echo "ADE_LOCATION=$ADE_LOCATION" 
echo "ADE_RG_NAME=$ADE_RG_NAME"
echo "ADE_KV_NAME=$ADE_KV_NAME"
echo "ADE_KV_ID=$ADE_KV_ID"
echo "ADE_KV_URI=$ADE_KV_URI"
echo "ADE_KEK_NAME=$ADE_KEK_NAME"
echo "ADE_KEK_ID=$ADE_KV_ID"
echo "ADE_KEK_URI=$ADE_KEK_URI"

if [ "$ADE_AAD" = true ]; then
    # if aad was requested, then also print the corresponding AAD information
    echo "ADE_ADAPP_NAME=$ADE_ADAPP_NAME"
    echo "ADE_ADAPP_SECRET=$ADE_ADAPP_SECRET"
    echo "ADE_ADAPP_CERT_NAME=$ADE_ADAPP_CERT_NAME"
    echo "ADE_KV_CERT_THUMB=$ADE_KV_CERT_THUMB"
    echo "ADE_KV_CERT_SID=$ADE_KV_CERT_SID"
fi
