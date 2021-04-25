## Prerequisites

## Create an Azure Container Registry

az group create --name MyResourceGroup --location eastus
az acr create --resource-group MyResourceGroup --name MyHelmACR --sku Basic
## Create an AKS cluster

az aks create -g MyResourceGroup -n MyAKS --location eastus  --attach-acr MyHelmACR --generate-ssh-keys
## Connect to your AKS cluster

## Download the sample application

## Create a Dockerfile

## Build and push the sample application to the ACR

az acr build --image webfrontend:v1 \
  --registry MyHelmACR \
  --file Dockerfile .
## Create your Helm chart

## Run your Helm chart

## Delete the cluster

az group delete --name MyResourceGroup --yes --no-wait
## Next steps
