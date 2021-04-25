## Before you begin

## Create an ingress controller

az aks show --resource-group myResourceGroup --name myAKSCluster --query nodeResourceGroup -o tsv
az network public-ip create --resource-group MC_myResourceGroup_myAKSCluster_eastus --name myAKSPublicIP --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv
az network public-ip list --resource-group MC_myResourceGroup_myAKSCluster_eastus --query "[?ipAddress=='myAKSPublicIP'].[dnsSettings.fqdn]" -o tsv
## Install cert-manager

## Create a CA cluster issuer

## Run demo applications

## Create an ingress route

## Create a certificate object

## Test the ingress configuration

## Clean up resources

az network public-ip delete --resource-group MC_myResourceGroup_myAKSCluster_eastus --name myAKSPublicIP
## Next steps
