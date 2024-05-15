# Run this script in Azure Cloud Shell, PowerShell environment, or PowerShell 7
# Passed validation in Azure Cloud Shell, PowerShell environment, on 4/25/2024

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


# </ValidateFileValues>


# <ValidateScriptLogic>


# </ValidateScriptLogic>


# <FullScript>
# </FullScript>
