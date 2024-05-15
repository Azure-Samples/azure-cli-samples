#!/bin/bash
# Passed validation in Ubuntu 22.04.3 LTS on 4/29/2024

# <VariableBlock>
# Variable block

# Replace these three variable values with actual values
subscriptionID=00000000-0000-0000-0000-00000000
csvFileLocation="myFilePath\myFileName.csv"
logFileLocation="myFilePath\myLogName.txt"

# Variable values that contain a prefix can be replaced with the prefix of your choice.
#   These prefixes have a random ID appended to them in the script.
# Variable values without a prefix will be overwritten by the contents of your CSV file.
location=""
createRG=""
newRgName="msdocs-rg-"
existingRgName=""

createVnet=""
vnetName="msdocs-vnet-"
subnetName="msdocs-subnet-"
vnetAddressPrefix=""
subnetAddressPrefixes=""

vmName="msdocs-vm-"
vmImage=""
publicIpSku=""
adminUser=""
adminPassword="msdocs-PW-@"

# set your azure subscription 
az account set --subscription $subscriptionID
# </VariableBlock>

# <ValidateFileValues>
while IFS=, read -r resourceNo location createRG existingRgName createVnet vnetAddressPrefix subnetAddressPrefixes vmImage publicIpSku adminUser
do
    let "randomIdentifier=$RANDOM*$RANDOM"
    if [ "$resourceNo" = "1" ]; then
      echo "resourceNo = $resourceNo"
      echo "location = $location"
      echo ""

      echo "RESOURCE GROUP INFORMATION:"
      echo "createRG = $createRG"
      if [ "$createRG" = "TRUE" ]; then 
        echo "newRGName = $newRgName$randomIdentifier"
      else
        echo "exsitingRgName = $existingRgName"
      fi
      echo ""

      echo "VNET INFORMATION:"
      echo "createVnet = $createVnet"
      if [ "$createVnet" = "TRUE" ]; then 
        echo "vnetName = $vnetName$randomIdentifier"
        echo "subnetName = $subnetName$randomIdentifier"
        echo "vnetAddressPrefix = $vnetAddressPrefix"
        echo "subnetAddressPrefixes = $subnetAddressPrefixes"
      fi
      echo ""

      echo "VM INFORMATION:"
      echo "vmName = $vmName$randomIdentifier"
      echo "vmImage = $vmImage"
      echo "vmSku= $publicIpSku"
      echo "vmAdminUser = $adminUser"
      echo "vmAdminPassword = $adminPassword$randomIdentifier"
    fi  
# skip the header line
done < <(tail -n +2 $csvFileLocation)
# </ValidateFileValues>

# <ValidateScriptLogic>
# validate script logic
echo "Validating script">$logFileLocation
while IFS=, read -r resourceNo location createRG existingRgName createVnet vnetAddressPrefix subnetAddressPrefixes vmImage publicIpSku adminUser
do
    echo "resourceNo = $resourceNo">>$logFileLocation
    let "randomIdentifier=$RANDOM*$RANDOM"
    
    if [ "$createRG" == "TRUE" ]; then
      echo "will create RG $newRgName$randomIdentifier">>$logFileLocation
      existingRgName=$newRgName$randomIdentifier
    fi
    
    if [ "$createVnet" == "TRUE" ]; then
      echo "will create VNet $vnetName$randomIdentifier in RG $existingRgName">>$logFileLocation
      echo "will create VM $vmName$randomIdentifier in Vnet $vnetName$randomIdentifier in RG $existingRgName">>$logFileLocation
    else
      echo "will create VM $vmName$randomIdentifier in RG $existingRgName">>$logFileLocation
    fi

# skip the header line
done < <(tail -n +2 $csvFileLocation)

# read your log file
clear
cat $logFileLocation
# </ValidateScriptLogic>

# <FullScript>
# create Azure resources
echo "Creating Azure resources">$logFileLocation
while IFS=, read -r resourceNo location createRG existingRgName createVnet vnetAddressPrefix subnetAddressPrefixes vmImage publicIpSku adminUser
do
    echo "resourceNo = $resourceNo">>$logFileLocation
    let "randomIdentifier=$RANDOM*$RANDOM"

    if [ "$createRG" == "TRUE" ]; then
      echo "creating RG $newRgName$randomIdentifier">>$logFileLocation
      az group create --location $location --name $newRgName$randomIdentifier
      existingRgName=$newRgName$randomIdentifier
      echo "RG $newRgName$randomIdentifier creation complete">>$logFileLocation
    fi

    if [ "$createVnet" == "TRUE" ]; then
      echo "creating VNet $vnetName$randomIdentifier in RG $existingRgName with adrPX $vnetAddressPrefix, snName $subnetName$randomIdentifier and snPXs $subnetAddressPrefixes">>$logFileLocation
      az network vnet create \
          --name $vnetName$randomIdentifier \
          --resource-group $existingRgName \
          --address-prefix $vnetAddressPrefix \
          --subnet-name $subnetName$randomIdentifier \
          --subnet-prefixes $subnetAddressPrefixes
      echo "VNet $vnetName$randomIdentifier creation complete">>$logFileLocation
      
      echo "creating VM $vmName$randomIdentifier in Vnet $vnetName$randomIdentifier in RG $existingRgName">>$logFileLocation
      az vm create \
          --resource-group $existingRgName \
          --name $vmName$randomIdentifier \
          --image $vmImage \
          --vnet-name $vnetName$randomIdentifier \
          --subnet $subnetName$randomIdentifier \
          --public-ip-sku $publicIpSku \
          --admin-username $adminUser\
          --admin-password $adminPassword$randomIdentifier
      echo "VM $vmName$randomIdentifier creation complete">>$logFileLocation
    
    else
      
      echo "creating VM $vmName$randomIdentifier in RG $existingRgName">>$logFileLocation
      az vm create \
          --resource-group $existingRgName \
          --name $vmName$randomIdentifier \
          --image $vmImage \
          --public-ip-sku $publicIpSku \
          --admin-username $adminUser\
          --admin-password $adminPassword$randomIdentifier
      echo "VM $vmName$randomIdentifier creation complete">>$logFileLocation
    
    fi
# skip the header line
done < <(tail -n +2 $csvFileLocation)

# read your log file
# clear
cat $logFileLocation
# </FullScript>
