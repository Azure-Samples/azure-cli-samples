#!/usr/bin/env bash
set -e

RESOURCE_GROUP='az-cli-custom-vhd'
STORAGE_PREFIX='customimagevm'
LOCATION='westus'

# Read in the public key
if [[ -r ~/.ssh/id_rsa.pub ]]; then
    SSH_PUB_KEY=$(cat ~/.ssh/id_rsa.pub)
else
    read -e -p "I couldn't find ~/.ssh/id_rsa.pub. Please provide a path to your public key: " FILE_PATH
    eval FILE_PATH=${FILE_PATH}
    while [ ! -e ${FILE_PATH} ]; do
        read -e -p "I couldn't find $FILE_PATH. Please provide a path to your public key: " FILE_PATH
    done
    SSH_PUB_KEY=`cat ${FILE_PATH}`
fi


# Create the resource group if it doesn't exist
echo "Creating resource group ${RESOURCE_GROUP} in ${LOCATION}"
az group create -n ${RESOURCE_GROUP} -l ${LOCATION} 1>/dev/null

# Create the storage account to upload the custom vhd. If the storage provider has not been registered, run:
# `az provider register --namespace "Microsoft.Storage"`
STORAGE_NAME=$(az storage account list --query "[?starts_with(name, '${STORAGE_PREFIX}')] | [0].name" -o tsv)
if [[ ${STORAGE_NAME} ]]; then
    echo "Storage account ${STORAGE_NAME} already exists"
else
    while [[ ! ${STORAGE_NAME} ]]; do
        RANDOM_NUM=$(python -S -c "import random; print(random.randrange(1000, 63000))")
        STORAGE_NAME=${STORAGE_PREFIX}${RANDOM_NUM}

        echo "Creating a premium storage account named ${STORAGE_NAME}"
        if [[ $(az storage account check-name --name ${STORAGE_NAME} --query "nameAvailable") == 'true' ]]; then
            az storage account create -g ${RESOURCE_GROUP} -n ${STORAGE_NAME} -l ${LOCATION} --sku PREMIUM_LRS 1>/dev/null
        else
            echo "Storage name: ${STORAGE_NAME} was already taken... Trying again"
            STORAGE_NAME=''
        fi
    done
fi


# Upload the VHD to the storage account
echo "Fetching storage account key for use in container and blob manipulations"
STORAGE_KEY=$(az storage account keys list -g ${RESOURCE_GROUP} -n ${STORAGE_NAME} --query "[?keyName=='key1'] | [0].value" -o tsv)

if [[ $(az storage blob exists -c vhds -n sample.vhd --account-name ${STORAGE_NAME} --account-key ${STORAGE_KEY} --query "exists" -o tsv) == 'false' ]]; then
    # Create the container for the vhd
    echo "Creating the container for the vhd"
    az storage container create -n vhds --account-name ${STORAGE_NAME} --account-key ${STORAGE_KEY} 1>/dev/null

    # Create the vhd blob
    echo "Creating the vhd blob"
    az storage blob upload -c vhds -f ~/sample.vhd -n sample.vhd --account-name ${STORAGE_NAME} --account-key ${STORAGE_KEY} 1>/dev/null
else
    echo "Found sample.vhd blob in container vhds, so we are going to assume, it is up-to-date"
fi


# Create the VM if it doesn't already exist
VM_NAME=$(az vm list -g ${RESOURCE_GROUP} --query "[?name=='custom-vm'].name" -o tsv)
if [[ VM_NAME ]]; then
    echo "VM named custom-vm in ${RESOURCE_GROUP} already exists."
else
    # Create the vm from the custom image
    echo "Creating a virtual machine from the custom vhd"
    az vm create -g ${RESOURCE_GROUP} -n custom-vm --image "https://${STORAGE_NAME}.blob.core.windows.net/vhds/sample.vhd" \
        --os-type linux --admin-username deploy 1>/dev/null
fi


# Ensure ssh access to the VM for this user by resetting the current ssh key for the deploy user
echo "Ensure the deploy user can authenicate with ~/.ssh/id_rsa.pub"
az vm access set-linux-user -g ${RESOURCE_GROUP} -n custom-vm -u deploy --ssh-key-value "${SSH_PUB_KEY}" 1>/dev/null


# Get public IP address for the VM
IP_ADDRESS=$(az vm list-ip-addresses -g az-cli-custom-vhd -n custom-vm \
    --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)

echo ""
echo "You can now connect via 'ssh deploy@${IP_ADDRESS}'"