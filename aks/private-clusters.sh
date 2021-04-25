L=westus
LOAD_BALANCER_SKU=standard
ENABLE_PRIVATE_CLUSTER= 
RESOURCE_GROUP=<private-cluster-resource-group>
NETWORK_PLUGIN=azure
VNET_SUBNET_ID=<subnet-id>
DOCKER_BRIDGE_ADDRESS=172.17.0.1/16
DNS_SERVICE_IP=10.2.0.10
SERVICE_CIDR=10.2.0.0/24 
ASSIGN_IDENTITY=<ResourceId>
FQDN_SUBDOMAIN=<subdomain-name>
## Region availability

## Prerequisites

## Create a private AKS cluster

az group create -l $L -n MyResourceGroup
az aks create -n <private-cluster-name> -g <private-cluster-resource-group> --load-balancer-sku $LOAD_BALANCER_SKU --enable-private-cluster $ENABLE_PRIVATE_CLUSTER
az aks create --resource-group $RESOURCE_GROUP --name <private-cluster-name> --load-balancer-sku $LOAD_BALANCER_SKU --network-plugin $NETWORK_PLUGIN --vnet-subnet-id $VNET_SUBNET_ID --docker-bridge-address $DOCKER_BRIDGE_ADDRESS --dns-service-ip $DNS_SERVICE_IP --service-cidr $SERVICE_CIDR
## Configure Private DNS Zone 

az aks create -n <private-cluster-name> -g <private-cluster-resource-group> --load-balancer-sku $LOAD_BALANCER_SKU --assign-identity $ASSIGN_IDENTITY --private-dns-zone [system|none]
az aks create -n <private-cluster-name> -g <private-cluster-resource-group> --load-balancer-sku $LOAD_BALANCER_SKU --assign-identity $ASSIGN_IDENTITY --private-dns-zone <custom private dns zone ResourceId> --fqdn-subdomain $FQDN_SUBDOMAIN
## Options for connecting to the private cluster

az feature register --namespace "Microsoft.ContainerService" --name "RunCommandPreview"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/RunCommandPreview')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
az aks command invoke -g <resourceGroup> -n <clusterName> -c "kubectl get pods -n kube-system"
az aks command invoke -g <resourceGroup> -n <clusterName> -c "kubectl apply -f deployment.yaml -n default" -f deployment.yaml
az aks command invoke -g <resourceGroup> -n <clusterName> -c "kubectl apply -f deployment.yaml -n default" -f .
az aks command invoke -g <resourceGroup> -n <clusterName> -c "helm repo add bitnami https://charts.bitnami.com/bitnami && helm repo update && helm install my-release -f values.yaml bitnami/nginx" -f values.yaml
## Virtual network peering

## Hub and spoke with custom DNS

## Limitations 
