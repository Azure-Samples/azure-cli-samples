## Before you begin

## Create an Azure Container Registry

az group create --name myResourceGroup --location eastus
az acr create --resource-group myResourceGroup --name <acrName> --sku Basic
## Log in to the container registry

az acr login --name <acrName>
## Tag a container image

az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table
## Push images to registry

## List images in registry

az acr repository list --name <acrName> --output table
az acr repository show-tags --name <acrName> --repository azure-vote-front --output table
## Next steps
