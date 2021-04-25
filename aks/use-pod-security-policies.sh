NAMESPACE=Microsoft.ContainerService
RESOURCE_GROUP=myResourceGroup
## Before you begin

# Install the aks-preview extension
az extension add --name aks-preview
az feature register --name PodSecurityPolicyPreview --namespace $NAMESPACE
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/PodSecurityPolicyPreview')].{Name:name,State:properties.state}"
az provider register --namespace $NAMESPACE
## Overview of pod security policies

## Enable pod security policy on an AKS cluster

az aks update --resource-group $RESOURCE_GROUP --name myAKSCluster
## Default AKS policies

## Create a test user in an AKS cluster

## Test the creation of a privileged pod

## Test creation of an unprivileged pod

## Test creation of a pod with a specific user context

## Create a custom pod security policy

## Allow user account to use the custom pod security policy

## Test the creation of an unprivileged pod again

## Clean up resources

az aks update --resource-group $RESOURCE_GROUP --name myAKSCluster
## Next steps
