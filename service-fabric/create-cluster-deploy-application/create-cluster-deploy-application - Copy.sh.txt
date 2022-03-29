#!/bin/bash
# Passed validation in Cloud Shell on 3/21/2022

# <FullScript>
# Create a secure Service Fabric Linux cluster

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-service-fabric-rg-$randomIdentifier"
tag="create-cluster-deploy-application"
cluster="msdocs-cluster-$randomIdentifier"
password="Pa$$w0rD-$randomIdentifier"
subject="msdocs-cluster.eastus.cloudapp.azure.com" 
vault="msdocskeyvault$randomIdentifier" 
vmUser="azureuser"
vmPassword="vmPa$$w0rD-$randomIdentifier"
size="5"
os="UbuntuServer1604"
application="msdocs-application-$randomIdentifier"
appType="msdocs-application-type-$randomIdentifier"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create key vault
echo "Creating $vault"
az keyvault create --name $vault --resource-group $resourceGroup --enabled-for-deployment true

# Create secure five node Linux cluster. Create a certficate in the key vault. 
# The certificate's subject name must match the domain that you use to access the Service Fabric cluster.
# The certificate is downloaded locally.
echo "Creating $cluster"
az sf cluster create \
  --resource-group $resourceGroup \
  --location "$location" \
  --certificate-password $password \
  --cluster-size $size \
  --vm-password $vmPassword \
  --vm-user-name $vmUser  \
  --certificate-output-folder . \
  --certificate-subject-name $subject \
  --vault-name $vault \
  --vault-rg $resourceGroup \
  --cluster-name $cluster \
  --os $os

# Create application type
echo "Creating $appType"
az sf application-type create \
  --resource-group $resourceGroup \
  --cluster-name $cluster \
  --application-type-name $appType

# Create application version
az sf application-type version create \
  --resource-group $resourceGroup \
  --cluster-name $cluster \
  --application-type-name $appType \
  --version 1.0 \
  --package-url "https://sftestapp.blob.core.windows.net/sftestapp/testApp_1.0.sfpkg"

# List application type
  az sf application-type list \
  --resource-group $resourceGroup \
  --cluster-name $cluster

# Create application in the cluster
echo "Creating $application in $cluster"
az sf application create \
  --resource-group $resourceGroup \
  --cluster-name $cluster \
  --application-name $application \
  --application-type-name $appType \
  --application-type-version v1 \
  --package-url "https://sftestapp.blob.core.windows.net/sftestapp/testApp_1.0.sfpkg" \
  --application-parameters key0=value0

az sf application create \
  --resource-group $resourceGroup \
  --cluster-name $cluster \
  --application-name $application \
  --application-type-name $appType \
  --application-type-version v1 \
  --application-parameters key0=value0

# List application in the cluster
echo "List $application in $cluster"
az sf application list \
--resource-group $resourceGroup \
--cluster-name $cluster

# Upgrade application
echo "Upgrading $application in $cluster"
az sf application update \
--resource-group $resourceGroup \
--cluster-name $cluster
  --application-name $application \
--minimum-nodes 1 \
--maximum-nodes 3

# Delete application
echo "Deleting $application"
az sf application delete \
--resource-group $resourceGroup \
--cluster-name $cluster \
--application-name $application
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
