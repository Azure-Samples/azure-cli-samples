LOCATION=eastus
NODE_VM_SIZE=Standard_D3_v2
SERVICE_PRINCIPAL=<APPID>
CLIENT_SECRET=<PASSWORD>
SKU=Standard_LRS
## Prerequisites

## Create an AKS cluster

az group create --name mySparkCluster --location $LOCATION
az ad sp create-for-rbac --name SparkSP
az aks create --resource-group mySparkCluster --name mySparkCluster --node-vm-size $NODE_VM_SIZE --service-principal $SERVICE_PRINCIPAL --client-secret $CLIENT_SECRET
az aks get-credentials --resource-group mySparkCluster --name mySparkCluster
## Build the Spark source

## Prepare a Spark job

## Copy job to storage

RESOURCE_GROUP=sparkdemo
STORAGE_ACCT=sparkdemo$RANDOM
az group create --name $RESOURCE_GROUP --location $LOCATION
az storage account create --resource-group $RESOURCE_GROUP --name $STORAGE_ACCT --sku $SKU
export AZURE_STORAGE_CONNECTION_STRING=`az storage account show-connection-string --resource-group $RESOURCE_GROUP --name $STORAGE_ACCT -o tsv`
CONTAINER_NAME=jars
BLOB_NAME=SparkPi-assembly-0.1.0-SNAPSHOT.jar
FILE_TO_UPLOAD=target/scala-2.11/SparkPi-assembly-0.1.0-SNAPSHOT.jar
## Submit a Spark job

## Get job results and logs

## Package jar with container image

## Next steps
