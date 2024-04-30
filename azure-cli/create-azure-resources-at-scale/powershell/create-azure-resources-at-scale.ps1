# Passed validation in Ubuntu 22.04.3 LTS on 4/29/2024

# <VariableBlock>
# Variable block
$subscriptionID = "00000000-0000-0000-0000-00000000"
$setupFileLocation = "myFilePath\myFileName.csv"
$logFileLocation = "myFilePath\myLogName.txt"

# These variables are placeholders whose values are replaced from the csv input file, or appended to a random ID.
$location = ""
$createRG = ""
$newRgName = "msdocs-rg-"
$existingRgName = ""
$createVnet = ""

$vmName = "msdocs-vm-"
$vmImage = ""
$publicIpSku = ""
$adminUser = ""
$adminPassword = "msdocs-pw-"

$vnetName = "msdocs-vnet-"
$subnetName = "msdocs-subnet-"
$vnetAddressPrefix = ""
$subnetAddressPrefix = ""

# Set Azure subscription
Set-AzContext -SubscriptionId $subscriptionID
# </VariableBlock>

# <ValidateFileValues>
#Skip the header line
$csvData = Import-Csv -Path $setupFileLocation | Select-Object -Skip 1
foreach ($row in $csvData) {
    $randomIdentifier = [int]([math]::Abs([System.Random]::new().Next()))
    $resourceNo = $row.resourceNo
    $location = $row.location
    $createRG = $row.createRG
    $existingRgName = $row.existingRgName
    $createVnet = $row.createVnet
    $vmImage = $row.vmImage
    $publicIpSku = $row.publicIpSku
    $adminUser = $row.adminUser
    $vnetAddressPrefix = $row.vnetAddressPrefix
    $subnetAddressPrefix = $row.subnetAddressPrefix

    Write-Host "resourceNo = $resourceNo"
    Write-Host "location = $location"
    Write-Host ""

    Write-Host "RESOURCE GROUP INFORMATION:"
    Write-Host "createRG = $createRG"
    if ($createRG -eq "TRUE") {
        Write-Host "newRGName = $newRgName$randomIdentifier"
    }
    else {
        Write-Host "existingRgName = $existingRgName"
    }
    Write-Host ""

    Write-Host "VNET INFORMATION:"
    Write-Host "createVnet = $createVnet"
    if ($createVnet -eq "TRUE") {
        Write-Host "vnetName = $vnetName$randomIdentifier"
        Write-Host "subnetName = $subnetName$randomIdentifier"
        Write-Host "vnetAddressPrefix = $vnetAddressPrefix"
        Write-Host "subnetAddressPrefix = $subnetAddressPrefix"
    }
    Write-Host ""

    Write-Host "VM INFORMATION:"
    Write-Host "vmName = $vmName$randomIdentifier"
    Write-Host "vmImage = $vmImage"
    Write-Host "vmSku = $publicIpSku"
    Write-Host "vmAdminUser = $adminUser"
    Write-Host "vmAdminPassword = $adminPassword$randomIdentifier"
}
# </ValidateFileValues>

# <ValidateScriptLogic>
# Validate script logic
Write-Output "Validating script" | Out-File -FilePath $logFileLocation

#Skip the header line
$csvData = Import-Csv -Path $setupFileLocation | Select-Object -Skip 1
foreach ($row in $csvData) {
    $resourceNo = $row.resourceNo
    $randomIdentifier = [int]([math]::Abs([System.Random]::new().Next()))
    $createRG = $row.createRG
    $createVnet = $row.createVnet

    Write-Output "resourceNo = $resourceNo" | Out-File -FilePath $logFileLocation -Append
    if ($createRG -eq "TRUE") {
        Write-Output "creating RG $newRgName$randomIdentifier" | Out-File -FilePath $logFileLocation -Append
        $existingRgName = "$newRgName$randomIdentifier"
    }
    if ($createVnet -eq "TRUE") {
        Write-Output "creating VNet $vnetName$randomIdentifier in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
        Write-Output "creating VM $vmName$randomIdentifier within Vnet $vnetName$randomIdentifier in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
    }
    else {
        Write-Output "creating VM $vmName$randomIdentifier without Vnet in RG $existingRgName" | Out-File -FilePath $logFileLocation -Append
    }

    # Read your log file
    Clear-Host
    Get-Content -Path $logFileLocation
}

# </ValidateScriptLogic>

# <FullScript>
# create Azure resources
$logFileLocation = "C:\path\to\log.txt"
$setupFileLocation = "C:\path\to\setup.csv"

#Skip the header line
Get-Content $setupFileLocation | Select-Object -Skip 1 | ForEach-Object {
    $resourceNo, $location, $createRG, $existingRgName, $createVnet, $vmImage, $publicIpSku, $adminUser, $vnetAddressPrefix, $subnetAddressPrefix = $_ -split ','

    Add-Content $logFileLocation "resourceNo = $resourceNo"

    $randomIdentifier = (Get-Random) * (Get-Random)

    if ($createRG -eq "TRUE") {
        Add-Content $logFileLocation "creating RG $($newRgName)$randomIdentifier"
        az group create --location $location --name $($newRgName)$randomIdentifier
        $existingRgName = "$($newRgName)$randomIdentifier"
    }

    if ($createVnet -eq "TRUE") {
        Add-Content $logFileLocation "creating VNet $($vnetName)$randomIdentifier in RG $existingRgName"
        az network vnet create `
            --name "$($vnetName)$randomIdentifier" `
            --resource-group $existingRgName `
            --address-prefix $vnetAddressPrefix `
            --subnet-name "$($subnetName)$randomIdentifier" `
            --subnet-prefixes $subnetAddressPrefix

        Add-Content $logFileLocation "creating VM $($vmName)$randomIdentifier within Vnet $($vnetName)$randomIdentifier in RG $existingRgName"
        az vm create `
            --resource-group $existingRgName `
            --name "$($vmName)$randomIdentifier" `
            --image $vmImage `
            --vnet-name "$($vnetName)$randomIdentifier" `
            --public-ip-sku $publicIpSku `
            --admin-username $adminUser `
            --admin-password "$($adminPassword)$randomIdentifier"
    } else {
        Add-Content $logFileLocation "creating VM $($vmName)$randomIdentifier without Vnet in RG $existingRgName"
        az vm create `
            --resource-group $existingRgName `
            --name "$($vmName)$randomIdentifier" `
            --image $vmImage `
            --public-ip-sku $publicIpSku `
            --admin-username $adminUser `
            --admin-password "$($adminPassword)$randomIdentifier"
    }
}
# </FullScript>
