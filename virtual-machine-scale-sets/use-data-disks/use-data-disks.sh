#!/bin/bash
# Passed validation in Cloud Shell on 1/27/2022

# <FullScript>
# Attach and use data disks with a virtual machine scale set

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-vmss-rg-$randomIdentifier"
tag="use-data-disks-vmss"
image="Ubuntu2204"
scaleSet="msdocs-scaleSet-$randomIdentifier"
upgradePolicyMode="automatic"
instanceCount="2"
login="azureuser"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a scale set
# Network resources such as an Azure load balancer are automatically created
# Two data disks are created and attach - a 64Gb disk and a 128Gb disk
echo "Creating $scaleSet with $instanceCount instances"
az vmss create --resource-group $resourceGroup --name $scaleSet --image $image --upgrade-policy-mode $upgradePolicyMode --instance-count $instanceCount --admin-username $login --generate-ssh-keys --data-disk-sizes-gb 64 128

# Executes a script from a GitHub sample repo on each VM instance that prepares all the raw attached data disks
az vmss extension set --publisher Microsoft.Azure.Extensions --version 2.0 --name CustomScript --resource-group $resourceGroup --vmss-name $scaleSet --settings '{"fileUris":["https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/prepare_vm_disks.sh"],"commandToExecute":"./prepare_vm_disks.sh"}'

# See the disks for the scale set
echo "Showing the disks for the scale set"
az vmss show --resource-group $resourceGroup --name $scaleSet --query virtualMachineProfile.storageProfile.dataDisks

# Attach an additional 128 gb data disk
echo "Attaching additional 128 gb data disk to $scaleSet"
az vmss disk attach --resource-group $resourceGroup --vmss-name $scaleSet --size-gb 128

# See the disks for your virtual machine
echo "Showing the disks for $scaleSet"
az vmss show --resource-group $resourceGroup --name $scaleSet --query virtualMachineProfile.storageProfile.dataDisks

# Remove a managed disk from the scale set
echo "Removing a managed disk from $scaleSet"
az vmss disk detach --resource-group $resourceGroup --vmss-name $scaleSet --lun 2
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
