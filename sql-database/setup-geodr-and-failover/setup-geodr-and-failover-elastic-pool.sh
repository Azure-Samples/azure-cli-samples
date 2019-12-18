# Connect-AzAccount

$subscriptionId = ''
$primaryResourceGroupName = "myPrimaryResourceGroup-$(Get-Random)"
$secondaryResourceGroupName = "mySecondaryResourceGroup-$(Get-Random)"
$primaryLocation = "westus2"
$secondaryLocation = "eastus"
$primaryServerName = "primary-server-$(Get-Random)"
$secondaryServerName = "secondary-server-$(Get-Random)"
$adminSqlLgin = "SqlAdmin"
$password = "ChangeYourAdminPassword1"
$databaseName = "mySampleDatabase"
$primaryPoolName = "PrimaryPool"
$secondarypoolname = "SecondaryPool"

# The ip address ranges that you want to allow to access your servers
$primaryStartIp = "0.0.0.0"
$primaryEndIp = "0.0.0.0"
$secondaryStartIp = "0.0.0.0"
$secondaryEndIp = "0.0.0.0"

# set the subscription context for the Azure account
az account set -s $subscriptionID

# create two new resource groups
az group create \
   --name $primaryResourceGroupName \
   --location $primaryLocation
az group create \
   --name $secondaryResourceGroupname \
   --location $secondaryLocation

# create two new logical servers with a system wide unique server name
az sql server create \
   --name $primaryServerName \
   --resource-group $primaryResourceGroupName \
   --location $primaryLocation  \
   --admin-user $adminSqlLgin \
   --admin-password $password
az sql server create \
   --name $secondaryServerName \
   --resource-group $secondaryResourceGroupName \
   --location $secondaryLocation  \
   --admin-user $adminSqlLgin \
   --admin-password $password

# create a server firewall rule for each server that allows access from the specified IP range
az sql server firewall-rule create --end-ip-address $primaryEndIp \
   --name "AllowedIPs" \
   --resource-group $primaryResourceGroupName \
   --server $primaryServerName \
   --start-ip-address $primaryStartIp 
az sql server firewall-rule create --end-ip-address $secondaryEndIp \
   --name "AllowedIPs" \
   --resource-group $secondaryResourceGroupName \
   --server $secondaryServerName \
   --start-ip-address $secondaryStartIp 

# create a pool in each of the servers
az sql elastic-pool create --name $primaryPoolName \
    --resource-group $primaryResourceGroupName \
    --server $primaryServerName \
    --capacity 50 \
    --db-dtu-max 50 \
    --db-dtu-min 10 \
    --edition "Standard"
az sql elastic-pool create --name $secondaryPoolName \
    --resource-group $secondaryResourceGroupName \
    --server $secondaryServerNamee \
    --capacity 50 \
    --db-dtu-max 50 \
    --db-dtu-min 10 \
    --edition "Standard"

# create a blank database in the pool on the primary server
az sql db create --name $databaseName \
   --resource-group $primaryResourceGroupName \
   --server $primaryServerName \
   --elastic-pool $primaryPoolName

# establish Active Geo-Replication
$database = Get-AzSqlDatabase -ResourceGroupName  `
    -ServerName  `
    -DatabaseName 
$database | New-AzSqlDatabaseSecondary -PartnerResourceGroupName  `
    -PartnerServerName  `
    -SecondaryElasticPoolName  `
    -AllowConnections "All"

az sql db replica create --name $databaseName
    --partner-server $secondaryServerName
    --resource-group $primaryResourceGroupName
    --server $primaryServerName
    --elastic-pool $secondaryPoolName
    --partner-resource-group $secondaryResourceGroupName

# initiate a planned failover
$database = Get-AzSqlDatabase -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -DatabaseName $databaseName 
$database | Set-AzSqlDatabaseSecondary -PartnerResourceGroupName $primaryResourceGroupName -Failover

# monitor Geo-Replication config and health after failover
$database = Get-AzSqlDatabase -ResourceGroupName $secondaryResourceGroupName `
    -ServerName $secondaryServerName `
    -DatabaseName $databaseName
$database | Get-AzSqlDatabaseReplicationLink -PartnerResourceGroupName $primaryResourceGroupName `
    -PartnerServerName $primaryServerName

# clean up deployment 
# az group delete --name $primaryResourceGroupName
# az group delete --name $secondaryResourceGroupName