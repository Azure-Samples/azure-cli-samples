F=public-svc.yaml
LOAD_BALANCER_OUTBOUND_IPS=<publicIpId1>,<publicIpId2>
LOAD_BALANCER_OUTBOUND_IP_PREFIXES=<publicIpPrefixId1>,<publicIpPrefixId2>
LB_NAME=kubernetes
LOAD_BALANCER_SKU=standard
LOAD_BALANCER_IDLE_TIMEOUT=4
## Before you begin

## Use the public standard load balancer

kubectl apply -f public-svc.yaml
kubectl get service public-svc
## Configure the public standard load balancer

az aks update --resource-group myResourceGroup --name myAKSCluster --load-balancer-managed-outbound-ip-count 2
az network public-ip show --resource-group myResourceGroup --name myPublicIP --query id -o tsv
az aks update --resource-group myResourceGroup --name myAKSCluster --load-balancer-outbound-ips $LOAD_BALANCER_OUTBOUND_IPS
az network public-ip prefix show --resource-group myResourceGroup --name myPublicIPPrefix --query id -o tsv
az aks update --resource-group myResourceGroup --name myAKSCluster --load-balancer-outbound-ip-prefixes $LOAD_BALANCER_OUTBOUND_IP_PREFIXES
az aks create --resource-group myResourceGroup --name myAKSCluster --load-balancer-outbound-ips $LOAD_BALANCER_OUTBOUND_IPS
az aks create --resource-group myResourceGroup --load-balancer-outbound-ip-prefixes $LOAD_BALANCER_OUTBOUND_IP_PREFIXES
NODE_RG=$(az aks show --resource-group myResourceGroup --name myAKSCluster --query nodeResourceGroup -o tsv)
az network lb outbound-rule list --resource-group $NODE_RG --lb-name $LB_NAME -o table
az aks update --resource-group myResourceGroup --name myAKSCluster --load-balancer-managed-outbound-ip-count 7 --load-balancer-outbound-ports 4000
az aks create --resource-group myResourceGroup --name myAKSCluster --load-balancer-sku $LOAD_BALANCER_SKU --load-balancer-managed-outbound-ip-count 2 --load-balancer-outbound-ports 1024 
az aks update --resource-group myResourceGroup --name myAKSCluster --load-balancer-idle-timeout $LOAD_BALANCER_IDLE_TIMEOUT
## Restrict inbound traffic to specific IP ranges

## Maintain the client's IP on inbound connections

## Additional customizations via Kubernetes Annotations

## Troubleshooting SNAT

## Moving from a basic SKU load balancer to standard SKU

## Limitations

## Next steps
