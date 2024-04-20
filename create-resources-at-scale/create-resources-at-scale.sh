#!/bin/bash

# Passed validation in Azure Cloud Shell Bash environment on 4/25/2022

# Variable block
# These variables have placeholder values that are replaced with values from the csv input file.
Identifier="0"
user=""
createvm="true"
createvnet="true"
createrg="true"
subnet=""
vmName="msdocs-linuxVM-$user"
vnetname=""
vmImage="Ubuntu2204"
location=""
resourceGroup="msdocs-ubuntu-vm-group22-$Identifier"

# task 1 create resources
for i in $(seq 0 1);
do
    # Read in commands from csv file
    echo read in commands from csv file
    c1= sed -n "$Identifier"p file.csv
    Identifier=$((Identifier+1))
    echo $Identifier. Creating resources for $user
    resourceGroup="ubuntu-vm-group22-$Identifier"
    subnet="msdocs-vnet-$Identifier"
    az group create --l $location -n $resourceGroup
    echo $Identifier
    echo test echo
    if "$createvm" =true; then 
        echo create vm
        az vm create \
            --resource-group $resourceGroup \
            --name $vmName \
            --image $vmImage \
            --public-ip-sku Standard \
            --admin-username $user\
            --admin-password qwertY123456  
    fi
    if "$createvnet" =true; then 
    echo create vnet
    az network vnet create \    
        --name $vnetname \
        --resource-group $resourceGroup \
        --address-prefix 10.0.0.0/16 \
        --subnet-name $subnet-$Identifier \
        --subnet-prefixes 10.0.0.0/24
    fi    
    az group delete -n $resourceGroup -y
    echo deleted $resourceGroup
    done 2>&1 >> output.txt
echo done