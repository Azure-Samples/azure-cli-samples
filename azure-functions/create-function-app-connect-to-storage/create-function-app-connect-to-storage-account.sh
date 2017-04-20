# create a resource group with location
az group create --name myResourceGroup --location westeurope

# create a storage account 
az storage account create --name myfunctionappstorage --location westeurope --resource-group myResourceGroup --sku Standard_LRS

# create a new function app, assign it to the resource group you have just created
az functionapp create --name myFunction --resource-group myResourceGroup --storage-account myfunctionappstorage --consumption-plan-location westeurope
