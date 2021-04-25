## The following limitations apply:

## Before you begin

## Azure AD authentication overview

## Create Azure AD server component

# Create the Azure AD application
serverApplicationId=$(az ad app create \
    --display-name "${aksname}Server" \
    --identifier-uris "https://${aksname}Server" \
    --query appId -o tsv)
# Create a service principal for the Azure AD application
az ad sp create --id $serverApplicationId
az ad app permission add \
    --id $serverApplicationId \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role
az ad app permission grant --id $serverApplicationId --api 00000003-0000-0000-c000-000000000000
az ad app permission admin-consent --id  $serverApplicationId
## Create Azure AD client component

clientApplicationId=$(az ad app create \
    --display-name "${aksname}Client" \
    --native-app \
    --reply-urls "https://${aksname}Client" \
    --query appId -o tsv)
az ad sp create --id $clientApplicationId
oAuthPermissionId=$(az ad app show --id $serverApplicationId --query "oauth2Permissions[0].id" -o tsv)
az ad app permission add --id $clientApplicationId --api $serverApplicationId --api-permissions ${oAuthPermissionId}=Scope
az ad app permission grant --id $clientApplicationId --api $serverApplicationId
## Deploy the cluster

az group create --name myResourceGroup --location EastUS
tenantId=$(az account show --query tenantId -o tsv)
az aks get-credentials --resource-group myResourceGroup --name $aksname --admin
## Create Kubernetes RBAC binding

az ad signed-in-user show --query userPrincipalName -o tsv
## Access cluster with Azure AD

az aks get-credentials --resource-group myResourceGroup --name $aksname --overwrite-existing
## Next steps
