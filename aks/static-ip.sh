## Before you begin

## Create a static IP address

az network public-ip create \
    --resource-group myResourceGroup \
    --name myAKSPublicIP \
    --sku Standard \
    --allocation-method static
az network public-ip show --resource-group myResourceGroup --name myAKSPublicIP --query ipAddress --output tsv
## Create a service using the static IP address

az role assignment create \
    --assignee <Client ID> \
    --role "Network Contributor" \
    --scope /subscriptions/<subscription id>/resourceGroups/<resource group name>
## Apply a DNS label to the service

## Troubleshoot

## Next steps
