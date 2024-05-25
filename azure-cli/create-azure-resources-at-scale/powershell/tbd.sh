# Run this script in Azure Cloud Shell, PowerShell environment, or PowerShell 7
# Passed validation in Azure Cloud Shell, PowerShell environment, on 4/25/2024


# <step1>
# Variable block

# Replace these three variable values with actual values
[CmdletBinding()]
param (
    [string]$csvFileLocation = 'myFileName.csv'
)

$logFileLocation = "myLogFile.txt"
$subscriptionID = "00000000-0000-0000-0000-00000000"

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

# Set your Azure subscription 
az account set --subscription $subscriptionID

# Import your CSV data
$data = Import-Csv $csvFileLocation -delimiter ","
# </step1>

# <step2>
# Verify CSV columns are being read correctly

# Take a look at the CSV contents
$data | Format-Table

# Validate select CSV row values
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
# </step2>

# <step3>
# Validate script logic

# Create the log file
"SCRIPT LOGIC VALIDATION." | Out-File -FilePath $logFileLocation

# Loop through each row in the CSV file
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
  
  # Log resource number and random ID
  "" | Out-File -FilePath $logFileLocation -Append
  "resourceNo = $resourceNo" | Out-File -FilePath $logFileLocation -Append
  "randomIdentifier = $randomIdentifier" | Out-File -FilePath $logFileLocation -Append
  
  # Check if a new resource group should be created
  if ($createRG -eq "TRUE") {
    "will create RG $newRgName$randomIdentifier" | Out-File -FilePath $logFileLocation -Append
    $existingRgName = "$newRgName$randomIdentifier"
  }
  
  # Check if a new virtual network should be created, then create a VM
  if ($createVnet -eq "TRUE") {
    "will create VNet $vnetName$randomIdentifier in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
    "will create VM $vmName$randomIdentifier in VNet $vnetName$randomIdentifier in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
  } else {
    "will create VM $vmName$randomIdentifier in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
  }
}

# Clear the console (optional) and display the log file
# Clear-Host
Get-Content -Path $logFileLocation
# </step3>

# <step4>
# Create Azure resources

# Create the log file
"CREATE AZURE RESOURCES." | Out-File -FilePath $logFileLocation

# Loop through each CSV row
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
  
  # Log resource number, random ID and display start time
  "" | Out-File -FilePath $logFileLocation -Append
  "resourceNo = $resourceNo" | Out-File -FilePath $logFileLocation -Append
  "randomIdentifier = $randomIdentifier" | Out-File -FilePath $logFileLocation -Append
  Write-Host "Starting creation of resourceNo $resourceNo at $(Get-Date -format 'u')."
  
  # Check if a new resource group should be created
  if ($createRG -eq "TRUE") {
    Write-Host "creating RG $newRgName$randomIdentifier" | Out-File -FilePath $logFileLocation -Append
    az group create --location $location --name $newRgName$randomIdentifier
    $existingRgName = "$newRgName$randomIdentifier"
    Write-Host "RG $newRgName$randomIdentifier creation complete" | Out-File -FilePath $logFileLocation -Append
    }
  
  # Check if a new virtual network should be created, then create the VM
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

# Clear the console (optional) and display the log file
# Clear-Host
Get-Content -Path $logFileLocation
# </step4>
