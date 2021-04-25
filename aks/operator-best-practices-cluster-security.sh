RESOURCE_GROUP=myResourceGroup
NAME=myAKSCluster
## Secure access to the API server and cluster nodes

## Secure container access to resources

## Regularly update to the latest version of Kubernetes

az aks get-upgrades --resource-group $RESOURCE_GROUP --name $NAME
## Process Linux node updates and reboots using kured

## Next steps
