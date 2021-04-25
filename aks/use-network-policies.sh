$RESOURCE_GROUP_NAME=""
NODE_COUNT=1
SERVICE_CIDR=10.0.0.0/16
DNS_SERVICE_IP=10.0.0.10
DOCKER_BRIDGE_ADDRESS=172.17.0.1/16
$SUBNET_ID=""
$SP_ID=""
$SP_PASSWORD=""
NETWORK_PLUGIN=azure
$WINDOWS_USERNAME=""
VM_SET_TYPE=VirtualMachineScaleSets
KUBERNETES_VERSION=1.20.2
$CLUSTER_NAME=""
OS_TYPE=Windows
## Before you begin

## Overview of network policy

## Create an AKS cluster and enable network policy

RESOURCE_GROUP_NAME=myResourceGroup-NP
CLUSTER_NAME=myAKSCluster
LOCATION=canadaeast
az aks create --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --node-count $NODE_COUNT --service-cidr $SERVICE_CIDR --dns-service-ip $DNS_SERVICE_IP --docker-bridge-address $DOCKER_BRIDGE_ADDRESS --vnet-subnet-id $SUBNET_ID --service-principal $SP_ID --client-secret $SP_PASSWORD --network-plugin $NETWORK_PLUGIN --network-policy azure
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME
az feature register --namespace "Microsoft.ContainerService" --name "EnableAKSWindowsCalico"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableAKSWindowsCalico')].{Name:name,State:properties.state}"
az provider register --namespace Microsoft.ContainerService
echo "Please enter the username to use as administrator credentials for Windows Server containers on your cluster: " && read WINDOWS_USERNAME
az aks create --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --node-count $NODE_COUNT --service-cidr $SERVICE_CIDR --dns-service-ip $DNS_SERVICE_IP --docker-bridge-address $DOCKER_BRIDGE_ADDRESS --vnet-subnet-id $SUBNET_ID --service-principal $SP_ID --client-secret $SP_PASSWORD --windows-admin-username $WINDOWS_USERNAME --vm-set-type $VM_SET_TYPE --kubernetes-version $KUBERNETES_VERSION --network-plugin $NETWORK_PLUGIN --network-policy calico
az aks nodepool add --resource-group $RESOURCE_GROUP_NAME --cluster-name $CLUSTER_NAME --os-type $OS_TYPE --name npwin --node-count $NODE_COUNT
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME
## Deny all inbound traffic to a pod

## Allow inbound traffic based on a pod label

## Allow traffic only from within a defined namespace

## Clean up resources

## Next steps
