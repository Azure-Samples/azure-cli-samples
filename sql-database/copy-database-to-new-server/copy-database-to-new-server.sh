# Connect-AzAccount

$subscriptionId = ''
$sourceResourceGroupName = "mySourceResourceGroup-$(Get-Random)"
$sourceResourceGroupLocation = "westus2"
$targetResourceGroupname = "myTargetResourceGroup-$(Get-Random)"
$targetResourceGroupLocation = "eastus"
$adminSqlLogin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
$sourceServerName = "source-server-$(Get-Random)"
$targetServerName = "target-server-$(Get-Random)"
$sourceDatabaseName = "mySampleDatabase"
$targetDatabaseName = "CopyOfMySampleDatabase"

# The ip address range that you want to allow to access your servers
$sourceStartIp = "0.0.0.0"
$sourceEndIp = "0.0.0.0"
$targetStartIp = "0.0.0.0"
$targetEndIp = "0.0.0.0"

# set the subscription context for the Azure account
az account set -s $subscriptionID

# create two new resource groups
az group create \
   --name $sourceResourceGroupName \
   --location $sourceResourceGroupLocation
az group create \
   --name $targetResourceGroupname \
   --location $targetResourceGroupLocation

# create a server with a system wide unique server name
az sql server create \
   --name $sourceServerName \
   --resource-group $sourceResourceGroupName \
   --location $sourceResourceGroupLocation  \
   --admin-user $adminSqlLogin \
   --admin-password $password
az sql server create \
   --name $targetServerName \
   --resource-group $targetResourceGroupname \
   --location $targetResourceGroupLocation  \
   --admin-user $adminSqlLogin \
   --admin-password $password

# create a server firewall rule that allows access from the specified IP range
az sql server firewall-rule create --end-ip-address $sourceEndIp \
   --name "AllowedIPs" \
   --resource-group $sourceResourceGroupName \
   --server $sourceServerName \
   --start-ip-address $sourcestartip 
az sql server firewall-rule create --end-ip-address $targetEndIp \
   --name "AllowedIPs" \
   --resource-group $targetResourceGroupname \
   --server $targetServerName \
   --start-ip-address $targetStartIp

# create a blank database in the source-server with an S0 performance level
az sql db create --name $sourceDatabaseName \
   --resource-group $sourceResourceGroupName \
   --server $sourceServerName \
   --service-objective S0

# copy source database to the target server 
az sql db copy --dest-name $targetDatabaseName \
    --dest-resource-group $targetResourceGroupname \
    --dest-server $targetServerName \
    --name $sourceDatabaseName \
    --resource-group $sourceResourceGroupName \
    --server $sourceServerName

# clean up deployment 
# az group delete --name $sourceResourceGroupName
# az group delete --name $targetResourceGroupname