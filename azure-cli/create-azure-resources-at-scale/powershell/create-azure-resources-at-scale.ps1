# Run this script in Azure Cloud Shell, PowerShell environment, or PowerShell 7
# Passed validation in Azure Cloud Shell, PowerShell environment, on 4/25/2024

# <VariableBlock>
# Variable block
$subscriptionID=00000000-0000-0000-0000-00000000
$setupFileLocation="myFilePath\myFileName.csv"
$logFileLocation="myFilePath\myLogName.txt"

# These variables are placeholders whose values are replaced from the csv input file, or appended to a random ID.
$location=""
$createRG=""
$newRgName="msdocs-rg-"
$existingRgName=""
$createVnet=""

$vmName="msdocs-vm-"
$vmImage=""
$publicIpSku=""
$adminUser=""
$adminPassword="msdocs-pw-"

$vnetName="msdocs-vnet-"
$subnetName="msdocs-subnet-"
$vnetAddressPrefix=""
$subnetAddressPrefix=""

# set azure subscription 
az account set --subscription $subscriptionID
# </VariableBlock>

# <ValidateFileValues>
# </ValidateFileValues>


# <ValidateScriptLogic>
# </ValidateScriptLogic>


# <FullScript>
# </FullScript>
