#!/bin/bash
# Passed validation in Cloud Shell on 1/27/2022

# <FullScript>
# Create a virtual machine scale set from a custom VM image

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
subcriptionId=$(az account show --query id -o tsv)
location="East US"
resourceGroup="msdocs-vmss-rg-$randomIdentifier"
tag="create-use-custom-image-vmss"
image="Ubuntu2204"
virtualMachine="msdocs-vm-$randomIdentifier"
login="azureuser"
imageGallery="msdocsimagegalleryvmss$randomIdentifier"
imageDefinition="msdocs-image-definition-vmss-$randomIdentifier"
imageVersion="msdocs-image-version-$randomIdentifier"
scaleSet="msdocs-scaleSet-$randomIdentifier"
upgradePolicyMode="automatic"

# Create a resource group
echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create virtual machine from Ubuntu2204 image
echo "Create $virtualMachine from $image image"
az vm create --resource-group $resourceGroup --name $virtualMachine --image $image --admin-username $login --generate-ssh-keys --public-ip-sku Standard

# Create a resource group for images
# echo "Creating $resourceGroup in $location..."
# az group create --name $resourceGroup --location "$location" --tags $tag
# az group create --name myGalleryRG --location eastus

# Create an image gallery
echo "Creating $imageGallery"
az sig create --resource-group $resourceGroup \
--gallery-name $imageGallery

# Create image definition
echo "Creating $imageDefinition from $imageGallery"
az sig image-definition create --resource-group $resourceGroup \
--gallery-name $imageGallery \
--gallery-image-definition $imageDefinition \
--publisher myPublisher \
--offer myOffer \
--sku mySKU \
--os-type Linux \
--os-state specialized
# az sig image-definition create --resource-group myGalleryRG --gallery-name myGallery --gallery-image-definition myImageDefinition --publisher myPublisher --offer myOffer --sku mySKU --os-type Linux --os-state specialized

# Create image version
echo "Creating $imageVersion from $imageDefinition"
az sig image-version create  --resource-group $resourceGroup  --gallery-name $imageGallery  --gallery-image-definition $imageDefinition  --gallery-image-version 1.0.0  --target-regions "southcentralus=1" "eastus=1"  --managed-image "/subscriptions/$subcriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$virtualMachine"

# Create a scale set from custom image
echo "Creating $scaleSet from custom image"
az vmss create --resource-group $resourceGroup --name $scaleSet --image "/subscriptions/$subcriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/galleries/$imageGallery/images/$imageDefinition" --specialized
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y

