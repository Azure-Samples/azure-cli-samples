#!/bin/bash
 
# Passed validation in Azure Cloud Shell Bash environment on 4/25/2022
 
# Variable block
# These variables have placeholder values that are replaced with values from the csv input file.
subscriptionID=3618afcd-ea52-4ceb-bb46-53bb962d4e0b
lineCounter="0"
randomIdentifier=$RANDOM
user=""
adminPassword="msdocs-script-PS-$randomIdentifier"
createvm="true"
createvnet="true"
createrg="true"
subnet=""
vmName="msdocs-linuxVM-$user"
vnetname="msdocs-vnet-$user-$randomIdentifier"
vmImage="Ubuntu2204"
location=""
resourceGroup="msdocs-ubuntu-vm-group22-$randomIdentifier"
setupFileLocation="resource-metadata.csv"
publicIpSku=""
addressPrefix="10.0.0.0/16"
subnetPrefixes="10.0.0.0/24"
 
# select azure subscription
az account set --subscription $subscriptionID
 
OLDIFS=$IFS
IFS=','
[ ! -f $setupFileLocation ] && { echo "$setupFileLocation file not found"; exit 99; }
while read resourceNo createRG createVnet createVM location user subnet vmImage publicIpSku
do
	echo $resourceNo
	echo createRG
    echo "location is $location"
    printf $location
    az group create --l $location -n $resourceGroup
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
	echo $createVnet
    if "$createvnet" =true; then 
    echo create vnet
    az network vnet create \    
        --name $vnetname \
        --resource-group $resourceGroup \
        --address-prefix $addressPrefix \
        --subnet-name $subnet-$randomIdentifier \
        --subnet-prefixes $subnetPrefixes
    fi  
	echo Create $createVM
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
	echo $location
	echo $user
	echo $subnet
	echo $vmImage
	echo $publicIpSku
done < $setupFileLocation
IFS=$OLDIFS