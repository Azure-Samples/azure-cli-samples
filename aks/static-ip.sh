RESOURCE_GROUP=myResourceGroup
NAME=myAKSPublicIP
SKU=Standard
ALLOCATION_METHOD=static
ASSIGNEE=<Client ID>
ROLE="Network Contributor"
SCOPE=/subscriptions/<subscription id>/resourceGroups/<resource group name>
## Before you begin

## Create a static IP address

az network public-ip create --resource-group $RESOURCE_GROUP --name $NAME --sku $SKU --allocation-method $ALLOCATION_METHOD
az network public-ip show --resource-group $RESOURCE_GROUP --name $NAME --query ipAddress --output tsv
## Create a service using the static IP address

az role assignment create --assignee $ASSIGNEE --role $ROLE --scope $SCOPE
## Apply a DNS label to the service

## Troubleshoot

## Next steps
