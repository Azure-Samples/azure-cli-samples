SIZE_GB=20  
## Before you begin

## Create an Azure disk

az aks show --resource-group myResourceGroup --name myAKSCluster --query nodeResourceGroup -o tsv
az disk create   --resource-group MC_myResourceGroup_myAKSCluster_eastus   --name myAKSDisk   --size-gb $SIZE_GB --query id --output tsv
## Mount disk as volume

## Next steps
