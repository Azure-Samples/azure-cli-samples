# Passed validation in Ubuntu 22.04.3 LTS on 4/29/2024

# <VariableBlock>
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
$adminPassword = "msdocs-PW-@"

$vnetName = "msdocs-vnet-"
$subnetName = "msdocs-subnet-"
$vnetAddressPrefix = ""
$subnetAddressPrefixes = ""

# Set azure subscription
az account set --subscription $subscriptionID

# </ValidateFileValues>
# Validate file values

# Skip header line
$csvData = Import-Csv $setupFileLocation | Select-Object -Skip 1

foreach ($line in $csvData) {
    $resourceNo = $line.resourceNo
    $location = $line.location
    $createRG = $line.createRG
    $existingRgName = $line.existingRgName
    $createVnet = $line.createVnet
    $vnetAddressPrefix = $line.vnetAddressPrefix
    $subnetAddressPrefixes = $line.subnetAddressPrefixes
    $vmImage = $line.vmImage
    $publicIpSku = $line.publicIpSku
    $adminUser = $line.adminUser

    $randomIdentifier = Get-Random

    if ($resourceNo -eq "1") {
        Write-Output "resourceNo = $resourceNo"
        Write-Output "location = $location"
        Write-Output ""

        Write-Output "RESOURCE GROUP INFORMATION:"
        Write-Output "createRG = $createRG"
        if ($createRG -eq "TRUE") {
            Write-Output "newRGName = $($newRgName)$randomIdentifier"
        } else {
            Write-Output "existingRgName = $existingRgName"
        }
        Write-Output ""

        Write-Output "VNET INFORMATION:"
        Write-Output "createVnet = $createVnet"
        if ($createVnet -eq "TRUE") {
            Write-Output "vnetName = $($vnetName)$randomIdentifier"
            Write-Output "subnetName = $($subnetName)$randomIdentifier"
            Write-Output "vnetAddressPrefix = $vnetAddressPrefix"
            Write-Output "subnetAddressPrefixes = $subnetAddressPrefixes"
        }
        Write-Output ""

        Write-Output "VM INFORMATION:"
        Write-Output "vmName = $($vmName)$randomIdentifier"
        Write-Output "vmImage = $vmImage"
        Write-Output "vmSku = $publicIpSku"
        Write-Output "vmAdminUser = $adminUser"
        Write-Output "vmAdminPassword = $($adminPassword)$randomIdentifier"
    }
}

# </ValidateFileValues>

# <ValidateScriptLogic>
# Validate script logic
"Validating script" | Out-File $logFileLocation

# Skip header line
$setupData = Get-Content $setupFileLocation | Select-Object -Skip 1

foreach ($line in $setupData) {
    # Parse CSV line
    $resourceNo, $location, $createRG, $existingRgName, $createVnet, $vnetAddressPrefix, $subnetAddressPrefixes, $vmImage, $publicIpSku, $adminUser = $line -split ','

    # Log resource number
    "resourceNo = $resourceNo" | Out-File $logFileLocation -Append

    # Generate random identifier
    $randomIdentifier = Get-Random * Get-Random

    "create RG flag = $createRG" | Out-File $logFileLocation -Append
    "create Vnet flag = $createVnet" | Out-File $logFileLocation -Append

    # Check if a new resource group should be created
    if ($createRG -eq "TRUE") {
        $newRgName = $existingRgName + $randomIdentifier
        "will create RG $newRgName" | Out-File $logFileLocation -Append
        $existingRgName = $newRgName
    }

    # Check if a new VNet should be created
    if ($createVnet -eq "TRUE") {
        $vnetName = "VNet" + $randomIdentifier
        "will create VNet $vnetName in RG $existingRgName" | Out-File $logFileLocation -Append
        $vmName = "VM" + $randomIdentifier
        "will create VM $vmName in Vnet $vnetName in RG $existingRgName" | Out-File $logFileLocation -Append
    } else {
        $vmName = "VM" + $randomIdentifier
        "will create VM $vmName in RG $existingRgName" | Out-File $logFileLocation -Append
    }
}

# Display log file
Clear-Host
Get-Content $logFileLocation  

# </ValidateScriptLogic>

# <FullScript>
# Create Azure resources
"Creating Azure resources" > $logFileLocation

# Skip header line
$setupFileContent = Get-Content $setupFileLocation | Select-Object -Skip 1

foreach ($line in $setupFileContent) {
    $resourceDetails = $line.Split(',')
    $resourceNo = $resourceDetails[0]
    $location = $resourceDetails[1]
    $createRG = $resourceDetails[2]
    $existingRgName = $resourceDetails[3]
    $createVnet = $resourceDetails[4]
    $vnetAddressPrefix = $resourceDetails[5]
    $subnetAddressPrefixes = $resourceDetails[6]
    $vmImage = $resourceDetails[7]
    $publicIpSku = $resourceDetails[8]
    $adminUser = $resourceDetails[9]

    "resourceNo = $resourceNo" >> $logFileLocation
    $randomIdentifier = [System.Random]::new().Next(1, 1000000)

    if ($createRG -eq "TRUE") {
        $newRgName = "myRgName"
        $rgName = "$newRgName$randomIdentifier"
        "creating RG $rgName" >> $logFileLocation
        New-AzResourceGroup -Name $rgName -Location $location
        $existingRgName = $rgName
        "RG $rgName creation complete" >> $logFileLocation
    }

    if ($createVnet -eq "TRUE") {
        $vnetName = "myVnetName"
        $subnetName = "mySubnetName"
        $vmName = "myVmName"
        "creating VNet $($vnetName)$randomIdentifier in RG $existingRgName with adrPX $vnetAddressPrefix, snName $($subnetName)$randomIdentifier and snPXs $subnetAddressPrefixes" >> $logFileLocation
        $subnet = New-AzVirtualNetworkSubnetConfig -Name "$($subnetName)$randomIdentifier" -AddressPrefix $subnetAddressPrefixes
        $vnet = New-AzVirtualNetwork -Name "$($vnetName)$randomIdentifier" -ResourceGroupName $existingRgName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet
        "VNet $($vnetName)$randomIdentifier creation complete" >> $logFileLocation

        "creating VM $($vmName)$randomIdentifier in Vnet $($vnetName)$randomIdentifier in RG $existingRgName" >> $logFileLocation
        $adminPassword = "myAdminPassword$randomIdentifier"
        $vmConfig = New-AzVMConfig -VMName "$($vmName)$randomIdentifier" -VMSize "Standard_D2s_v3"
        $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName "$($vmName)$randomIdentifier" -Credential (New-Object System.Management.Automation.PSCredential ($adminUser, (ConvertTo-SecureString $adminPassword -AsPlainText -Force)))
        $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus $vmImage -Version "latest"
        $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $vnet.Subnets[0].Id -PublicIpAddressId (New-AzPublicIpAddress -ResourceGroupName $existingRgName -Location $location -AllocationMethod Static -SKU $publicIpSku).Id
        New-AzVM -ResourceGroupName $existingRgName -Location $location -VM $vmConfig
        "VM $($vmName)$randomIdentifier creation complete" >> $logFileLocation
    }
    else {
        $vmName = "myVmName"
        "creating VM $($vmName)$randomIdentifier in RG $existingRgName" >> $logFileLocation
        $adminPassword = "myAdminPassword$randomIdentifier"
        $vmConfig = New-AzVMConfig -VMName "$($vmName)$randomIdentifier" -VMSize "Standard_D2s_v3"
        $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName "$($vmName)$randomIdentifier" -Credential (New-Object System.Management.Automation.PSCredential ($adminUser, (ConvertTo-SecureString $adminPassword -AsPlainText -Force)))
        $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus $vmImage -Version "latest"
        $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id (New-AzPublicIpAddress -ResourceGroupName $existingRgName -Location $location -AllocationMethod Static -SKU $publicIpSku).Id
        New-AzVM -ResourceGroupName $existingRgName -Location $location -VM $vmConfig
        "VM $($vmName)$randomIdentifier creation complete" >> $logFileLocation
    }
}

# Read your log file
Get-Content $logFileLocation
# </FullScript>
