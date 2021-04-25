RESOURCE_GROUP=MyResourceGroup
SKU=Basic
G=MyResourceGroup
N=MyAKS
ATTACH_ACR=MyHelmACR
IMAGE=webfrontend:v1  
REGISTRY=MyHelmACR  
FILE=Dockerfile .
## Prerequisites

## Create an Azure Container Registry

az group create --name MyResourceGroup --location eastus
az acr create --resource-group $RESOURCE_GROUP --name MyHelmACR --sku $SKU
## Create an AKS cluster

az aks create -g $G -n $N --location eastus  --attach-acr $ATTACH_ACR
## Connect to your AKS cluster

## Download the sample application

## Create a Dockerfile

## Build and push the sample application to the ACR

az acr build --image $IMAGE --registry $REGISTRY --file $FILE
## Create your Helm chart

## Run your Helm chart

## Delete the cluster

az group delete --name MyResourceGroup
## Next steps
