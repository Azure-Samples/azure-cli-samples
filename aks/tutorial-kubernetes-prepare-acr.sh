LOCATION=eastus
RESOURCE_GROUP=myResourceGroup
SKU=Basic
REPOSITORY=azure-vote-front
## Before you begin

## Create an Azure Container Registry

az group create --name myResourceGroup --location $LOCATION
az acr create --resource-group $RESOURCE_GROUP --name <acrName> --sku $SKU
## Log in to the container registry

az acr login --name <acrName>
## Tag a container image

az acr list --resource-group $RESOURCE_GROUP --query "[].{acrLoginServer:loginServer}" --output table
## Push images to registry

## List images in registry

az acr repository list --name <acrName> --output table
az acr repository show-tags --name <acrName> --repository $REPOSITORY --output table
## Next steps
