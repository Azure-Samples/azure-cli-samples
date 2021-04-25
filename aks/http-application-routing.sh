## HTTP routing solution overview

## Deploy HTTP routing: CLI

az aks create --resource-group myResourceGroup --name myAKSCluster --enable-addons http_application_routing
az aks enable-addons --resource-group myResourceGroup --name myAKSCluster --addons http_application_routing
az aks show --resource-group myResourceGroup --name myAKSCluster --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName -o table
## Deploy HTTP routing: Portal

## Connect to your AKS cluster

az aks install-cli
az aks get-credentials --resource-group MyResourceGroup --name MyAKSCluster
## Use HTTP routing

## Remove HTTP routing

az aks disable-addons --addons http_application_routing --name myAKSCluster --resource-group myResourceGroup --no-wait
## Troubleshoot

## Clean up

## Next steps
