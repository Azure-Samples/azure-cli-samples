## Before you begin

## Limitations

## Summary of managed identities

## Create an AKS cluster with managed identities

# Create an Azure resource group
az group create --name myResourceGroup --location westus2
az aks create -g myResourceGroup -n myManagedCluster --enable-managed-identity
az aks get-credentials --resource-group myResourceGroup --name myManagedCluster
## Update an AKS cluster to managed identities (Preview)

az feature register --namespace Microsoft.ContainerService -n MigrateToMSIClusterPreview
az aks update -g <RGName> -n <AKSName> --enable-managed-identity
az feature register --namespace Microsoft.ContainerService -n UserAssignedIdentityPreview
az aks update -g <RGName> -n <AKSName> --enable-managed-identity --assign-identity <UserAssignedIdentityResourceID> 
## Obtain and use the system-assigned managed identity for your AKS cluster

az aks show -g <RGName> -n <ClusterName> --query "servicePrincipalProfile"
az aks show -g <RGName> -n <ClusterName> --query "identity"
## Bring your own control plane MI

az identity create --name myIdentity --resource-group myResourceGroup
az identity list --query "[].{Name:name, Id:id, Location:location}" -o table
az aks create \
    --resource-group myResourceGroup \
    --name myManagedCluster \
    --network-plugin azure \
    --vnet-subnet-id <subnet-id> \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24 \
    --enable-managed-identity \
    --assign-identity <identity-id> \
## Next steps
