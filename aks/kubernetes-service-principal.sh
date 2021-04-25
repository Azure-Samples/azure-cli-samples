## Before you begin

## Automatically create and use a service principal

az aks create --name myAKSCluster --resource-group myResourceGroup
## Manually create a service principal

az ad sp create-for-rbac --skip-assignment --name myAKSClusterServicePrincipal
## Specify a service principal for an AKS cluster

az aks create \
    --resource-group myResourceGroup \
    --name myAKSCluster \
    --service-principal <appId> \
    --client-secret <password>
## Delegate access to other Azure resources

az role assignment create --assignee <appId> --scope <resourceScope> --role Contributor
## Additional considerations

## Troubleshoot

## Next steps
