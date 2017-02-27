#!/bin/bash

# Source virtual machine details.
sourcevm=<Replace with vm name>
resourcegroup=<Replace with resource group name>

# Get the disk id for the source VM operating system disk.
diskid="$(az vm show -g $resourcegroup -n $sourcevm --query [storageProfile.osDisk.managedDisk.id] -o tsv)"
 
# Delete the source virtual machine, this will not delete the disk.
az vm delete -g $resourcegroup -n $sourcevm --force

# Create a new virtual machine, this creates SSH keys if not present.
az vm create --resource-group $resourcegroup --name myVM --image UbuntuLTS --generate-ssh-keys

# Attach disk as a data disk to the newly created VM.
az vm disk attach --resource-group $resourcegroup --vm-name myVM --disk $diskid

# Configure disk on new VM.
ip=$(az vm list-ip-addresses --resource-group $resourcegroup --name myVM --query '[].virtualMachine.network.publicIpAddresses[0].ipAddress' -o tsv)
ssh $ip 'sudo mkdir /mnt/remountedOsDisk'
ssh $ip 'sudo mount -t ext4 /dev/sdc1 /mnt/remountedOsDisk'
