RESOURCE_GROUP=myResourceGroup
NAME=myAKSCluster
G=MyResourceGroup
CLUSTER_NAME=MyManagedCluster
KUBERNETES_VERSION=KUBERNETES_VERSION
NAMESPACE=Microsoft.ContainerService
AUTO_UPGRADE_CHANNEL=stable
## Before you begin

## Check for available AKS cluster upgrades

az aks get-upgrades --resource-group $RESOURCE_GROUP --name $NAME --output table
## Customize node surge upgrade

# Set max surge for a new node pool
az aks nodepool add -n mynodepool -g $G --cluster-name $CLUSTER_NAME --max-surge 33%
# Update max surge for an existing node pool 
az aks nodepool update -n mynodepool -g $G --cluster-name $CLUSTER_NAME --max-surge 5
## Upgrade an AKS cluster

az aks upgrade --resource-group $RESOURCE_GROUP --name $NAME --kubernetes-version $KUBERNETES_VERSION
az aks show --resource-group $RESOURCE_GROUP --name $NAME --output table
## Set auto-upgrade channel

az feature register --namespace $NAMESPACE -n AutoUpgradePreview
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AutoUpgradePreview')].{Name:name,State:properties.state}"
az provider register --namespace $NAMESPACE
az aks create --resource-group $RESOURCE_GROUP --name $NAME --auto-upgrade-channel $AUTO_UPGRADE_CHANNEL
az aks update --resource-group $RESOURCE_GROUP --name $NAME --auto-upgrade-channel $AUTO_UPGRADE_CHANNEL
## Next steps
