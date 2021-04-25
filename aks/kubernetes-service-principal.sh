RESOURCE_GROUP=myResourceGroup
SERVICE_PRINCIPAL=<appId>
CLIENT_SECRET=<password>
ASSIGNEE=<appId>
SCOPE=<resourceScope>
ROLE=Contributor
## Before you begin

## Automatically create and use a service principal

az aks create --name myAKSCluster --resource-group $RESOURCE_GROUP
## Manually create a service principal

az ad sp create-for-rbac --name myAKSClusterServicePrincipal
## Specify a service principal for an AKS cluster

az aks create --resource-group $RESOURCE_GROUP --name myAKSCluster --service-principal $SERVICE_PRINCIPAL --client-secret $CLIENT_SECRET
## Delegate access to other Azure resources

az role assignment create --assignee $ASSIGNEE --scope $SCOPE --role $ROLE
## Additional considerations

## Troubleshoot

## Next steps
