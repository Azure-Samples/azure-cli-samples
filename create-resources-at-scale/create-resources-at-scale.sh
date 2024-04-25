#!/bin/bash

# Passed validation in Azure Cloud Shell Bash environment on 4/25/2022

# Variable block
# These variables have placeholder values that are replaced with values from the csv input file.
lineCounter="0"
randomIdentifier="$RANDOM*$RANDOM"
user=""
adminPassword="msdocs-script-PS-$randomIdentifier"
createvm="true"
createvnet="true"
createrg="true"
subnet=""
vmName="msdocs-linuxVM-$user"
vnetname=""
vmImage="Ubuntu2204"
location=""
resourceGroup="msdocs-ubuntu-vm-group22-$Identifier"
setupFileLocation="C:\myPath\myFileName"
publicIpSku=""

# task 1 create resources
for i in $(seq 0 1);
do
    # Read in commands from csv file
    echo Read in commands from csv file
    c1= sed -n "$lineCounter"p $setupFileLocation
    lineCounter=$((lineCounter+1))
    echo $lineCounter. Creating resources for $user
    resourceGroup="msdocs-script-rg-$randomIdentifier"
    subnet="msdocs-vnet-$randomIdentifier"
    az group create --l $location -n $resourceGroup
    echo test echo
    if "$createvm" =true; then 
        echo create vm
        az vm create \
            --resource-group $resourceGroup \
            --name $vmName \
            --image $vmImage \
            --public-ip-sku $publicIpSku \
            --admin-username $user\
            --admin-password $adminPassword  
    fi
    if "$createvnet" =true; then 
    echo create vnet
    az network vnet create \    
        --name $vnetname \
        --resource-group $resourceGroup \
        --address-prefix 10.0.0.0/16 \
        --subnet-name $subnet-$randomIdentifier \
        --subnet-prefixes 10.0.0.0/24
    fi    
    az group delete -n $resourceGroup -y
    echo deleted $resourceGroup
    done 2>&1 >> output.txt
echo done