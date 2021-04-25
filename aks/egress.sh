## Before you begin

## Egress traffic overview

## Create a static public IP

az aks show --resource-group myResourceGroup --name myAKSCluster --query nodeResourceGroup -o tsv
az network public-ip create \
    --resource-group MC_myResourceGroup_myAKSCluster_eastus \
    --name myAKSPublicIP \
    --allocation-method static
az network public-ip list --resource-group MC_myResourceGroup_myAKSCluster_eastus --query [0].ipAddress --output tsv
## Create a service with the static IP

## Verify egress address

## Next steps
