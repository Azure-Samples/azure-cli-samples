#!/bin/bash
# Passed validation in Azure Cloud Shell on 5/28/2024

# <step1>
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

# Set your Azure subscription 
az account set --subscription $subscriptionID
# </step1>

# <step2>
# Verify CSV columns are being read correctly

# Take a look at the CSV contents
cat $csvFileLocation

# Validate select CSV row values
while IFS=, read -r resourceNo location createRG existingRgName createVnet vnetAddressPrefix subnetAddressPrefixes vmImage publicIpSku adminUser
do
  # Generate a random ID
  let "randomIdentifier=$RANDOM*$RANDOM"

  # Return the values for the first data row
  # Change the $resourceNo to check different scenarios in your CSV
  if [ "$resourceNo" = "1" ]; then
    echo "resourceNo = $resourceNo"
    echo "location = $location"
    echo "randomIdentifier = $randomIdentifier"
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
    echo "vmSku = $publicIpSku"
    if [ `expr length "$adminUser"` == "1" ]; then
      echo "SSH keys will be generated."
    else
      echo "vmAdminUser = $adminUser"
      echo "vmAdminPassword = $adminPassword$randomIdentifier"        
    fi
  fi  
# skip the header line
done < <(tail -n +2 $csvFileLocation)
# </step2>

# <step3>
# Validate script logic

# Create the log file
echo "SCRIPT LOGIC VALIDATION.">$logFileLocation

# Loop through each row in the CSV file
while IFS=, read -r resourceNo location createRG existingRgName createVnet vnetAddressPrefix subnetAddressPrefixes vmImage publicIpSku adminUser
do
  # Generate a random ID
  let "randomIdentifier=$RANDOM*$RANDOM"
    
  # Log resource number and random ID
  echo "resourceNo = $resourceNo">>$logFileLocation
  echo "randomIdentifier = $randomIdentifier">>$logFileLocation

  # Check if a new resource group should be created
  if [ "$createRG" == "TRUE" ]; then
    echo "Will create RG $newRgName$randomIdentifier.">>$logFileLocation
    existingRgName=$newRgName$randomIdentifier
  fi

  # Check if a new virtual network should be created, then create the VM
  if [ "$createVnet" == "TRUE" ]; then
    echo "Will create VNet $vnetName$randomIdentifier in RG $existingRgName.">>$logFileLocation
    echo "Will create VM $vmName$randomIdentifier in Vnet $vnetName$randomIdentifier in RG $existingRgName.">>$logFileLocation
  else
    echo "Will create VM $vmName$randomIdentifier in RG $existingRgName.">>$logFileLocation
  fi
# Skip the header line.
done < <(tail -n +2 $csvFileLocation)

# Clear the console and display the log file
Clear
cat $logFileLocation
# </step3>

# <step4>
# Create Azure resources

# Create the log file
echo "CREATE AZURE RESOURCES.">$logFileLocation

# Loop through each CSV row
while IFS=, read -r resourceNo location createRG existingRgName createVnet vnetAddressPrefix subnetAddressPrefixes vmImage publicIpSku adminUser
do
  # Generate a random ID
  let "randomIdentifier=$RANDOM*$RANDOM"

  # Log resource number, random ID and display start time
  echo "resourceNo = $resourceNo">>$logFileLocation
  echo "randomIdentifier = $randomIdentifier">>$logFileLocation
  echo "Starting creation of resourceNo $resourceNo at $(date +"%Y-%m-%d %T")."

  # Check if a new resource group should be created
  if [ "$createRG" == "TRUE" ]; then
    echo "Creating RG $newRgName$randomIdentifier at $(date +"%Y-%m-%d %T").">>$logFileLocation
    az group create --location $location --name $newRgName$randomIdentifier >>$logFileLocation
    existingRgName=$newRgName$randomIdentifier
    echo "  RG $newRgName$randomIdentifier creation complete"
  fi

  # Check if a new virtual network should be created, then create the VM
  if [ "$createVnet" == "TRUE" ]; then
    echo "Creating VNet $vnetName$randomIdentifier in RG $existingRgName at $(date +"%Y-%m-%d %T").">>$logFileLocation
    az network vnet create \
        --name $vnetName$randomIdentifier \
        --resource-group $existingRgName \
        --address-prefix $vnetAddressPrefix \
        --subnet-name $subnetName$randomIdentifier \
        --subnet-prefixes $subnetAddressPrefixes >>$logFileLocation
    echo "  VNet $vnetName$randomIdentifier creation complete"
    
    echo "Creating VM $vmName$randomIdentifier in Vnet $vnetName$randomIdentifier in RG $existingRgName at $(date +"%Y-%m-%d %T").">>$logFileLocation
    az vm create \
        --resource-group $existingRgName \
        --name $vmName$randomIdentifier \
        --image $vmImage \
        --vnet-name $vnetName$randomIdentifier \
        --subnet $subnetName$randomIdentifier \
        --public-ip-sku $publicIpSku \
        --generate-ssh-keys >>$logFileLocation
    echo "  VM $vmName$randomIdentifier creation complete"
  else
    echo "Creating VM $vmName$randomIdentifier in RG $existingRgName at $(date +"%Y-%m-%d %T").">>$logFileLocation
    az vm create \
        --resource-group $existingRgName \
        --name $vmName$randomIdentifier \
        --image $vmImage \
        --public-ip-sku $publicIpSku \
        --admin-username $adminUser\
        --admin-password $adminPassword$randomIdentifier >>$logFileLocation
    echo "  VM $vmName$randomIdentifier creation complete"    
  fi
# skip the header line
done < <(tail -n +2 $csvFileLocation)

# Clear the console (optional) and display the log file
# clear
cat $logFileLocation
# </step4>
