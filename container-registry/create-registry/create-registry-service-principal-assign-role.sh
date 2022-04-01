#!/bin/bash
# Passed validation in Cloud Shell on 1/13/2022

# <FullScript>
# Create a container registry and a service principal

# https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli
# https://docs.microsoft.com/en-us/azure/container-registry/container-registry-quickstart-task-cli

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-container-registry-rg-$randomIdentifier"
tag="create-registry-service-principal-assign-role"
containerRegistry="msdocscontainerregistry$randomIdentifier"
registrySku="Basic"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create a container registry
az acr create --resource-group $resourceGroup \
  --name $containerRegistry --sku $registrySku

loginServer=$(az acr show --name $containerRegistry --resource-group $resourceGroup --query loginServer -o tsv)
echo $loginServer

# Take note of loginServer in the output, which is the fully qualified registry name (all lowercase).
# write query

# Log in to registry
az acr login --name $containerRegistry

# Push image to registry
docker pull mcr.microsoft.com/hello-world

docker tag mcr.microsoft.com/hello-world <login-server>/hello-world:v1
docker tag mcr.microsoft.com/hello-world mycontainerregistry.azurecr.io/hello-world:v1

docker push <login-server>/hello-world:v1
docker rmi <login-server>/hello-world:v1

# List container images
az acr repository list --name <registry-name> --output table
az acr repository show-tags --name <registry-name> --repository hello-world --output table

# Run image from registry
docker run <login-server>/hello-world:v1

# service-principal-create.sh

# Create a service principal
# https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal

#!/bin/bash
# This script requires Azure CLI version 2.25.0 or later. Check version with `az --version`.

# Modify for your environment.
# ACR_NAME: The name of your Azure Container Registry
# SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant
servicePrincipal=msdocs-acr-service-principal-$randomIdentifier

# Obtain the full registry ID for subsequent command args
registryId=$(az acr show --name $containerRegistry --query "id" --output tsv)
echo $registryId

# Create the service principal with rights scoped to the registry.
# Default permissions are for docker pull access. Modify the '--role'
# argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
PASSWORD=$(az ad sp create-for-rbac --name $servicePrincipal --scopes $registryId --role acrpull --query "password" --output tsv)
USER_NAME=$(az ad sp list --display-name $servicePrincipal --query "[].appId" --output tsv)

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
echo "Service principal ID: $USER_NAME"
echo "Service principal password: $PASSWORD"

# Modify role
# service-principal-assign-role.sh


# Modify for your environment. The ACR_NAME is the name of your Azure Container
# Registry, and the SERVICE_PRINCIPAL_ID is the service principal's 'appId' or
# one of its 'servicePrincipalNames' values.
ACR_NAME=mycontainerregistry
SERVICE_PRINCIPAL_ID=<service-principal-ID>

# Populate value required for subsequent command args
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)

# Assign the desired role to the service principal. Modify the '--role' argument
# value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
az role assignment create --assignee $SERVICE_PRINCIPAL_ID --scope $ACR_REGISTRY_ID --role acrpull


# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
