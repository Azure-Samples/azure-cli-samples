# Connect-AzAccount

$subscriptionId = ''
$resourceGroupName = "myResourceGroup-$(Get-Random)"
$location = "westeurope"
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
$serverName = "server-$(Get-Random)"
$databaseName = "myImportedDatabase"
$storageAccountName = "sqlimport$(Get-Random)"
$storageContainerName = "importcontainer$(Get-Random)"
$bacpacFilename = "sample.bacpac"

# The ip address range that you want to allow to access your server
$startip = "0.0.0.0"
$endip = "0.0.0.0"

# set the subscription context for the Azure account
az account set -s $subscriptionID

# create a resource group
az group create \
   --name $resourceGroupName \
   --location $location

# create a storage account 
az storage account create --name $storageAccountName \
    --resource-group $resourceGroupName \
    --location $location \
    --sku Standard_LRS

# create a storage container 
$storageContainer = New-AzStorageContainer -Name  `
    -Context $(New-AzStorageContext -StorageAccountName  `
        -StorageAccountKey $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName).Value[0])

az storage container create --name $storageContainerName
                            [--account-key]
                            [--account-name $storageAccountName
                            [--auth-mode {key, login}]
                            [--connection-string]
                            [--fail-on-exist]
                            [--metadata]
                            [--public-access {blob, container, off}]
                            [--sas-token]
                            [--subscription]
                            [--timeout]

# Download sample database from Github
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #required by Github
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac" -OutFile $bacpacfilename

# Upload sample database into storage container
Set-AzStorageBlobContent -Container  `
    -File  `
    -Context $(New-AzStorageContext -StorageAccountName  `
        -StorageAccountKey $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName).Value[0])

az storage blob upload --container-name $storagecontainername
                       --file $bacpacFilename
                       --name
                       [--account-key]
                       [--account-name $storageAccountName
                       [--auth-mode {key, login}]
                       [--connection-string]
                       [--content-cache-control]
                       [--content-disposition]
                       [--content-encoding]
                       [--content-language]
                       [--content-md5]
                       [--content-type]
                       [--if-match]
                       [--if-modified-since]
                       [--if-none-match]
                       [--if-unmodified-since]
                       [--lease-id]
                       [--max-connections]
                       [--maxsize-condition]
                       [--metadata]
                       [--no-progress]
                       [--sas-token]
                       [--socket-timeout]
                       [--subscription]
                       [--tier {P10, P20, P30, P4, P40, P50, P6, P60}]
                       [--timeout]
                       [--type {append, block, page}]
                       [--validate-content]

# create a new server with a system wide unique server name
az sql server create \
   --name $serverName \
   --resource-group $resourceGroupName \
   --location $location  \
   --admin-user $adminSqlLogin \
   --admin-password $password

# create a server firewall rule that allows access from the specified IP range
az sql server firewall-rule create --end-ip-address $endIp \
   --name "AllowedIPs" \
   --resource-group $resourceGroupName \
   --server $serverName \
   --start-ip-address $startIp 

# Import bacpac to database with an S3 performance level
$importRequest = New-AzSqlDatabaseImport -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -DatabaseMaxSizeBytes "262144000" `
    -StorageKeyType "StorageAccessKey" `
    -StorageKey $(Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName).Value[0] `
    -StorageUri "https://$storageaccountname.blob.core.windows.net/$storageContainerName/$bacpacFilename" `
    -Edition "Standard" `
    -ServiceObjectiveName "S3" `
    -AdministratorLogin "$adminSqlLogin" `
    -AdministratorLoginPassword $(ConvertTo-SecureString -String $password -AsPlainText -Force)

# Check import status and wait for the import to complete
$importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
[Console]::Write("Importing")
while ($importStatus.Status -eq "InProgress")
{
    $importStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write(".")
    Start-Sleep -s 10
}
[Console]::WriteLine("")
$importStatus

# Scale down to S0 after import is complete
Set-AzSqlDatabase -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName  `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0"

# clean up deployment 
# az group delete --name $resourceGroupName