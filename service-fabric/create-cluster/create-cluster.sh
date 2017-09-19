#!/bin/bash

# Variables
ResourceGroupName="aztestclustergroup" 
ClusterName="aztestcluster" 
Location="southcentralus" 
Password="q6D7nN%6ck@6" 
Subject="aztestcluster.southcentralus.cloudapp.azure.com" 
VaultName="aztestkeyvault" 
VmPassword="Mypa$$word!321"
VmUserName="sfadminuser"

# Create resource group
az group create --name $ResourceGroupName --location $Location 

# Create secure five node Linux cluster. Creates a key vault in a resource group
# and creates a certficate in the key vault. The certificate's subject name must match 
# the domain that you use to access the Service Fabric cluster.  The certificate is downloaded locally.
az sf cluster create --resource-group $ResourceGroupName --location $Location \ 
  --certificate-output-folder . --certificate-password $Password --certificate-subject-name $Subject \
  --cluster-name $ClusterName --cluster-size 5 --os UbuntuServer1604 --vault-name $VaultName \ 
  --vault-resource-group $ResourceGroupName --vm-password $VmPassword --vm-user-name $VmUserName
    