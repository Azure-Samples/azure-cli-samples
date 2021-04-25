RESOURCE_GROUP=myResourceGroup
NAME=myAKSCluster
$ACCOUNT_ID=""
## Before you begin

## Available cluster roles permissions

## Assign role permissions to a user or group

# Get the resource ID of your AKS cluster
AKS_CLUSTER=$(az aks show --resource-group myResourceGroup --name myAKSCluster --query id -o tsv)
## Get and verify the configuration information

az aks get-credentials --resource-group $RESOURCE_GROUP --name $NAME
## Remove role permissions

az role assignment delete --assignee $ACCOUNT_ID --scope $AKS_CLUSTER
## Next steps
