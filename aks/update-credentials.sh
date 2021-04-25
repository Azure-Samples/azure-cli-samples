RESOURCE_GROUP=myResourceGroup
AAD_SERVER_APP_ID=<SERVER APPLICATION ID>
AAD_SERVER_APP_SECRET=<SERVER APPLICATION SECRET>
AAD_CLIENT_APP_ID=<CLIENT APPLICATION ID>
## Before you begin

## Update or create a new service principal for your AKS cluster

SP_ID=$(az aks show --resource-group myResourceGroup --name myAKSCluster --query servicePrincipalProfile.clientId -o tsv)
az ad sp credential list --id $SP_ID --query "[].endDate" -o tsv
SP_ID=$(az aks show --resource-group myResourceGroup --name myAKSCluster --query servicePrincipalProfile.clientId -o tsv)
SP_SECRET=$(az ad sp credential reset --name $SP_ID --query password -o tsv)
az ad sp create-for-rbac
## Update AKS cluster with new service principal credentials

az aks update-credentials --resource-group $RESOURCE_GROUP --name myAKSCluster --service-principal $SP_ID --client-secret $SP_SECRET
## Update AKS Cluster with new AAD Application credentials

az aks update-credentials --resource-group $RESOURCE_GROUP --name myAKSCluster --aad-server-app-id $AAD_SERVER_APP_ID --aad-server-app-secret $AAD_SERVER_APP_SECRET --aad-client-app-id $AAD_CLIENT_APP_ID
## Next steps
