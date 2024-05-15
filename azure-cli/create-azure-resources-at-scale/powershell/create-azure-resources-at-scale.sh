# Run this script in Azure Cloud Shell, PowerShell environment, or PowerShell 7
# Passed validation in Azure Cloud Shell, PowerShell environment, on 4/25/2024


# <VariableBlock>
# Variable block

# Replace these three variable values with actual values
[CmdletBinding()]
param (
    [string]$csvFileLocation = 'resource-metadataPS.csv'
)

$logFileLocation = "myLogFile.txt"
$subscriptionID = "3618afcd-ea52-4ceb-bb46-53bb962d4e0b"

# Variable values that contain a prefix can be replaced with the prefix of your choice.
#   These prefixes have a random ID appended to them in the script.
# Variable values without a prefix will be overwritten by the contents of your CSV file.
$location=""
$createRG=""
$newRgName="msdocs-rg-"
$existingRgName=""

$createVnet=""
$vnetName="msdocs-vnet-"
$subnetName="msdocs-subnet-"
$vnetAddressPrefix=""
$subnetAddressPrefixes=""

$vmName="msdocs-vm-"
$vmImage=""
$publicIpSku=""
$adminUser=""
$adminPassword="msdocs-PW-@"

# set your azure subscription 
az account set --subscription $subscriptionID

# import your CSV data
$data = Import-Csv $csvFileLocation -delimiter ","
# </VariableBlock>

# <ValidateFileValues>
# read your imported file
$data | Format-Table

# Validate CSV data values
foreach ($row in $data) {
  $resourceNo = $row.resourceNo
  $location = $row.location
  $createRG = $row.createRG
  $existingRgName = $row.existingRgName
  $createVnet = $row.createVnet
  $vnetAddressPrefix = $row.vnetAddressPrefix
  $subnetAddressPrefixes = $row.subnetAddressPrefixes
  $vmImage = $row.vmImage
  $publicIpSku = $row.publicIpSku
  $adminUser = $row.adminUser
	
  # Generate a random ID
  $randomIdentifier = (New-Guid).ToString().Substring(0,8)
	
  if ($resourceNo -eq "1") {
    Write-Host "resourceNo = $resourceNo"
    Write-Host "location = $location"
    Write-Host ""
    
    Write-Host "RESOURCE GROUP INFORMATION:"
    Write-Host "createRG = $createRG"
    if ($createRG -eq "TRUE") {
        $newRgName = "$newRgName$randomIdentifier"
        Write-Host "newRGName = $newRgName"
    }
    else {
        Write-Host "exsitingRgName = $existingRgName"
    }
    Write-Host ""
    
    Write-Host "VNET INFORMATION:"
    Write-Host "createVnet = $createVnet"
    if ($createVnet -eq "TRUE") {
      Write-Host "vnetName = $vnetName$randomIdentifier"
      Write-Host "subnetName = $subnetName$randomIdentifier"
      Write-Host "vnetAddressPrefix = $vnetAddressPrefix"
      Write-Host "subnetAddressPrefixes = $subnetAddressPrefixes"
    }
    Write-Host ""
    
    Write-Host "VM INFORMATION:"
    Write-Host "vmName = $vmName$randomIdentifier"
    Write-Host "vmImage = $vmImage"
    Write-Host "vmSku= $publicIpSku"
    Write-Host "vmAdminUser = $adminUser"
    Write-Host "vmAdminPassword = $adminPassword$randomIdentifier"
    }
  }
# </ValidateFileValues>

# <ValidateScriptLogic>  
# Create the log file
"Validating script" | Out-File -FilePath $logFileLocation

foreach ($row in $data) {
  $resourceNo = $row.resourceNo
  $location = $row.location
  $createRG = $row.createRG
  $existingRgName = $row.existingRgName
  $createVnet = $row.createVnet
  $vnetAddressPrefix = $row.vnetAddressPrefix
  $subnetAddressPrefixes = $row.subnetAddressPrefixes
  $vmImage = $row.vmImage
  $publicIpSku = $row.publicIpSku
  $adminUser = $row.adminUser

  # Generate a random ID
  $randomIdentifier = (New-Guid).ToString().Substring(0,8)
  
  # Log resource number
  "" | Out-File -FilePath $logFileLocation -Append
  "resourceNo = $resourceNo" | Out-File -FilePath $logFileLocation -Append
  
  # Check if a new resource group should be created
  if ($createRG -eq "TRUE") {
    "will create RG $newRgName$randomIdentifier" | Out-File -FilePath $logFileLocation -Append
    $existingRgName = "$newRgName$randomIdentifier"
  }
  
  # Check if a new virtual network should be created
  if ($createVnet -eq "TRUE") {
    "will create VNet $vnetName$randomIdentifier in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
    "will create VM $vmName$randomIdentifier in VNet $vnetName$randomIdentifier in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
  } else {
    "will create VM $vmName$randomIdentifier in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
  }
}

# Clear the console and display the log file
Clear-Host
Get-Content -Path $logFileLocation
# </ValidateScriptLogic>

# <FullScript>
# Create the log file
"Creating Azure resources" | Out-File -FilePath $logFileLocation

foreach ($row in $data) {
  $resourceNo = $row.resourceNo
  $location = $row.location
  $createRG = $row.createRG
  $existingRgName = $row.existingRgName
  $createVnet = $row.createVnet
  $vnetAddressPrefix = $row.vnetAddressPrefix
  $subnetAddressPrefixes = $row.subnetAddressPrefixes
  $vmImage = $row.vmImage
  $publicIpSku = $row.publicIpSku
  $adminUser = $row.adminUser
	
  # Generate a random ID
  $randomIdentifier = (New-Guid).ToString().Substring(0,8)
  
  # Log resource number
  "" | Out-File -FilePath $logFileLocation -Append
  "resourceNo = $resourceNo" | Out-File -FilePath $logFileLocation -Append
  
  # Check if a new resource group should be created
  if ($createRG -eq "TRUE") {
    Write-Host "creating RG $newRgName$randomIdentifier" | Out-File -FilePath $logFileLocation -Append
    az group create --location $location --name $newRgName$randomIdentifier
    $existingRgName = "$newRgName$randomIdentifier"
    Write-Host "RG $newRgName$randomIdentifier creation complete" | Out-File -FilePath $logFileLocation -Append
    }
  
  # Check if a new virtual network should be created
  if ($createVnet -eq "TRUE") {
    Write-Host "creating VNet $vnetName$randomIdentifier in RG $existingRgName with adrPX $vnetAddressPrefix, snName $subnetName$randomIdentifier and snPXs $subnetAddressPrefixes" | Out-File -FilePath $logFileLocation -Append
    az network vnet create `
        --name $vnetName$randomIdentifier `
        --resource-group $existingRgName `
        --address-prefix $vnetAddressPrefix `
        --subnet-name $subnetName$randomIdentifier `
        --subnet-prefixes $subnetAddressPrefixes
    Write-Host "VNet $vnetName$randomIdentifier creation complete" | Out-File -FilePath $logFileLocation -Append
    
    Write-Host "creating VM $vmName$randomIdentifier in Vnet $vnetName$randomIdentifier in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
    az vm create `
        --resource-group $existingRgName `
        --name $vmName$randomIdentifier `
        --image $vmImage `
        --vnet-name $vnetName$randomIdentifier `
        --subnet $subnetName$randomIdentifier `
        --public-ip-sku $publicIpSku `
        --admin-username $adminUser`
        --admin-password $adminPassword$randomIdentifier
    Write-Host "VM $vmName$randomIdentifier creation complete" | Out-File -FilePath $logFileLocation -Append  
  } else {
    Write-Host "creating VM $vmName$randomIdentifier in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
    az vm create `
        --resource-group $existingRgName `
        --name $vmName$randomIdentifier `
        --image $vmImage `
        --public-ip-sku $publicIpSku `
        --admin-username $adminUser `
        --admin-password $adminPassword$randomIdentifier
    Write-Host "VM $vmName$randomIdentifier creation complete" | Out-File -FilePath $logFileLocation -Append
  }
}

# Clear the console and display the log file
# Clear-Host
Get-Content -Path $logFileLocation
# </FullScript>