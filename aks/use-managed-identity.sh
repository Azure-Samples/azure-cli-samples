LOCATION=westus2
RESOURCE_GROUP=myResourceGroup
NAMESPACE=Microsoft.ContainerService
NETWORK_PLUGIN=azure
VNET_SUBNET_ID=<subnet-id>
DOCKER_BRIDGE_ADDRESS=172.17.0.1/16
DNS_SERVICE_IP=10.2.0.10
SERVICE_CIDR=10.2.0.0/24
## Before you begin

## Limitations

## Summary of managed identities

## Create an AKS cluster with managed identities

# Create an Azure resource group
az group create --name myResourceGroup --location $LOCATION
az aks create -g myResourceGroup -n myManagedCluster
az aks get-credentials --resource-group $RESOURCE_GROUP --name myManagedCluster
## Update an AKS cluster to managed identities (Preview)

az feature register --namespace $NAMESPACE -n MigrateToMSIClusterPreview
az aks update -g <RGName> -n <AKSName>
az feature register --namespace $NAMESPACE -n UserAssignedIdentityPreview
az aks update -g <RGName> -n <AKSName> --assign-identity <UserAssignedIdentityResourceID> 
## Obtain and use the system-assigned managed identity for your AKS cluster

az aks show -g <RGName> -n <ClusterName> --query "servicePrincipalProfile"
az aks show -g <RGName> -n <ClusterName> --query "identity"
## Bring your own control plane MI

az identity create --name myIdentity --resource-group $RESOURCE_GROUP
az identity list --query "[].{Name:name, Id:id, Location:location}" -o table
az aks create --resource-group $RESOURCE_GROUP --name myManagedCluster --network-plugin $NETWORK_PLUGIN --vnet-subnet-id $VNET_SUBNET_ID --docker-bridge-address $DOCKER_BRIDGE_ADDRESS --dns-service-ip $DNS_SERVICE_IP --service-cidr $SERVICE_CIDR --assign-identity <identity-id> \
## Next steps
