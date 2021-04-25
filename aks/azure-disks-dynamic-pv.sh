RESOURCE_GROUP=MC_myResourceGroup_myAKSCluster_eastus
## Before you begin

## Built-in storage classes

## Create a persistent volume claim

## Use the persistent volume

## Use Ultra Disks

## Back up a persistent volume

az disk list --query '[].id | [?contains(@,`pvc-faf0f176-8b8d-11e8-923b-deb28c58d242`)]' -o tsv
az snapshot create --resource-group $RESOURCE_GROUP --name pvcSnapshot --source /subscriptions/<guid>/resourceGroups/MC_myResourceGroup_myAKSCluster_eastus/providers/MicrosoftCompute/disks/kubernetes-dynamic-pvc-faf0f176-8b8d-11e8-923b-deb28c58d242
## Restore and use a snapshot

az disk create --resource-group $RESOURCE_GROUP --name pvcRestored --source pvcSnapshot
az disk show --resource-group $RESOURCE_GROUP --name pvcRestored --query id -o tsv
## Next steps
