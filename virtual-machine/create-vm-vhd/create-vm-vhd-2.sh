#!/bin/bash

# Create a resource group
az group create -n myResourceGroup -l westus

# Create the storage account to upload the vhd
az storage account create -g myResourceGroup -n mystorageaccount -l westus --sku PREMIUM_LRS

# Get a storage key for the storage account
STORAGE_KEY=$(az storage account keys list -g myResourceGroup -n mystorageaccount --query "[?keyName=='key1'] | [0].value" -o tsv)

# Create the container for the vhd
az storage container create -n vhds --account-name mystorageaccount --account-key ${STORAGE_KEY}

# Upload the vhd to a blob
az storage blob upload -c vhds -f ~/sample.vhd -n sample.vhd --account-name mystorageaccount --account-key ${STORAGE_KEY}

# Create the vm from the vhd
az vm create -g myResourceGroup -n myVM --image "https://myStorageAccount.blob.core.windows.net/vhds/sample.vhd" \
        --os-type linux --admin-username deploy --generate-ssh-keys

# Update the deploy user with your ssh key
az vm user update --resource-group myResourceGroup -n custom-vm -u deploy --ssh-key-value "$(< ~/.ssh/id_rsa.pub)"

# Get public IP address for the VM
IP_ADDRESS=$(az vm list-ip-addresses -g az-cli-vhd -n custom-vm \
    --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)

echo "You can now connect using 'ssh deploy@${IP_ADDRESS}'"