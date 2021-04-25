LOCATION=eastus
RESOURCE_GROUP=myResourceGroup
NODE_COUNT=1
## Region availability

## SLA terms and conditions

## Before you begin

## Creating a new cluster with Uptime SLA

# Create a resource group
az group create --name myResourceGroup --location $LOCATION
# Create an AKS cluster with uptime SLA
az aks create --resource-group $RESOURCE_GROUP --name myAKSCluster --node-count $NODE_COUNT
## Modify an existing cluster to use Uptime SLA

# Delete the existing cluster by deleting the resource group 
az group delete --name myResourceGroup
# Create a resource group
az group create --name myResourceGroup --location $LOCATION
# Create a new cluster without uptime SLA
az aks create --resource-group $RESOURCE_GROUP --name myAKSCluster--node-count 1
# Update an existing cluster to use Uptime SLA
 az aks update --resource-group myResourceGroup --name myAKSCluster --uptime-sla
 ```
## Opt out of Uptime SLA

# Update an existing cluster to opt out of Uptime SLA
 az aks update --resource-group myResourceGroup --name myAKSCluster --no-uptime-sla
 ```
## Clean up

az group delete --name myResourceGroup
## Next steps
