# setup values
appName="functionapp$random"
storageName="functionapp$random"
resourceGroup="functionapp$random"
location="WestEurope"

# create a resource group with location
az group create --name $resourceGroup --location $location

# create a storage account 
az storage account create --name $appName --location $location --resource-group $storageName --sku Standard_LRS

# create a new function app, assign it to the resource group you have just created
az functionapp create --name $appName --resource-group $resourceGroup --storage-account $storageName --consumption-plan-location $location

# Retreive the Storage Account connection string 
connstr=$(az storage account show-connection-string --name $storageName --resource-group $resourceGroup --query connectionString --output tsv)

# update function app settings to connect to storage account
az functionapp config appsettings update --name $appName --resource-group $resourceGroup --settings $connstr

