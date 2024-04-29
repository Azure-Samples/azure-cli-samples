#!/bin/bash
# Passed validation in Ubuntu 22.04.3 LTS on 4/29/2024

# <VariableBlock>
# Variable block
subscriptionID=00000000-0000-0000-0000-00000000
setupFileLocation="myFilePath\myFileName.csv"

# These variables are placeholders whose values are replaced from the csv input file, or appended to a random ID.
location=""
createRG=""
newRgName="msdocs-rg-"
existingRgName=""
createVnet=""

vmName="msdocs-vm-"
vmImage=""
publicIpSku=""
adminUser=""
adminPassword="msdocs-pw-"

vnetName="msdocs-vnet-"
subnetName="msdocs-subnet-"
vnetAddressPrefix=""
subnetAddressPrefix=""

# set azure subscription 
az account set --subscription $subscriptionID
# </VariableBlock>

# <ValidateFileValues>
# check a line in the CSV for expected values
while IFS=, read -r resourceNo location createRG existingRgName createVnet vmImage publicIpSku adminUser vnetAddressPrefix subnetAddressPrefix
do
    let "randomIdentifier=$RANDOM*$RANDOM"
    if [ "$resourceNo" = "1" ]; then
      echo "resourceNo =" $resourceNo
      echo "location =" $location
      echo ""

      echo "RESOURCE GROUP INFORMATION:"
      echo "createRG =" $createRG
      if [ "$createRG" = "TRUE" ]; then 
        echo "newRGName =" $newRgName$randomIdentifier
      else
        echo "exsitingRgName = "$existingRgName
      fi
      echo ""

      echo "VNET INFORMATION:"
      echo "createVnet =" $createVnet
      if [ "$createVnet" = "TRUE" ]; then 
        echo "vnetName =" $vnetName$randomIdentifier
        echo "subnetName =" $subnetName$randomIdentifier
        echo "vnetAddressPrefix =" $vnetAddressPrefix
        echo "subnetAddressPrefix =" $subnetAddressPrefix
      fi
      echo ""

      echo "VM INFORMATION:"
      echo "vmName =" $vmName$randomIdentifier
      echo "vmImage =" $vmImage
      echo "vmSku =" $publicIpSku
      echo "vmAdminUser = " $adminUser
      echo "vmAdminPassword = " $adminPassword$randomIdentifier
    fi  
# skip the header line
done < <(tail -n +2 $setupFileLocation)
# </ValidateFileValues>

# <ValidateScriptLogic>
# validate script logic
while IFS=, read -r resourceNo location createRG existingRgName createVnet vmImage publicIpSku adminUser vnetAddressPrefix subnetAddressPrefix
do
    echo "resourceNo =" $resourceNo
    let "randomIdentifier=$RANDOM*$RANDOM"
    
    echo "create RG =" $createRG
    echo "create Vnet =" $createVnet
    
    if [ "$createRG" == "TRUE" ]; then
      echo "creating RG "$newRgName$randomIdentifier
      existingRgName=$newRgName$randomIdentifier
    fi
    
    if [ "$createVnet" == "TRUE" ]; then
      echo "creating VNet" $vnetName$randomIdentifier "in RG" $existingRgName
      echo "creating VM" $vmName$randomIdentifier "within Vnet" $vnetName$randomIdentifier "in RG" $existingRgName
    else
      echo "creating VM "$vmName$randomIdentifier "without Vnet in RG" $existingRgName
    fi
# skip the header line
done < <(tail -n +2 $setupFileLocation)
# </ValidateScriptLogic>

# <FullScript>
# create Azure resources
while IFS=, read -r resourceNo location createRG existingRgName createVnet vmImage publicIpSku adminUser vnetAddressPrefix subnetAddressPrefix
do
    echo "resourceNo =" $resourceNo
    echo "create RG="$createRG
    echo "create Vnet="$createVnet
    let "randomIdentifier=$RANDOM*$RANDOM"

    if [ "$createRG" == "TRUE" ]; then
      echo "creating RG "$newRgName$randomIdentifier
      az group create --location $location --name $newRgName$randomIdentifier
      existingRgName=$newRgName$randomIdentifier
    fi

    if [ "$createVnet" == "TRUE" ]; then
      echo "creating VNet" $vnetName$randomIdentifier "in RG" $existingRgName
      az network vnet create \    
          --name $vnetName$randomIdentifier \
          --resource-group $existingRgName \
          --address-prefix $vnetAddressPrefix \
          --subnet-name $subnetName$randomIdentifier \
          --subnet-prefixes $subnetAddressPrefix

      echo "creating VM" $vmName$randomIdentifier "within Vnet" $vnetName$randomIdentifier "in RG" $existingRgName
      az vm create \
          --resource-group $existingRgName \
          --name $vmName$randomIdentifier \
          --image $vmImage \
          --vnet-name $$vnetName$randomIdentifier
          --public-ip-sku $publicIpSku \
          --admin-username $adminUser\
          --admin-password $adminPassword$randomIdentifier
    else
      echo "creating VM "$vmName$randomIdentifier "without Vnet in RG" $existingRgName
      az vm create \
          --resource-group $existingRgName \
          --name $vmName$randomIdentifier \
          --image $vmImage \
          --public-ip-sku $publicIpSku \
          --admin-username $adminUser\
          --admin-password $adminPassword$randomIdentifier
    fi
# skip the header line
done < <(tail -n +2 $setupFileLocation)
# </FullScript>
