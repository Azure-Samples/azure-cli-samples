#!/bin/bash
 
# Passed validation in Azure Cloud Shell Bash environment on 4/25/2022
 
# Variable block
# These variables have placeholder values that are replaced with values from the csv input file.
subscriptionID=3618afcd-ea52-4ceb-bb46-53bb962d4e0b
lineCounter="0"
countLines=0
skipheaders=1
randomIdentifier=$RANDOM
user=""
adminPassword="msdocs-script-PS-$randomIdentifier"
createVM="true"
createVnet="true"
createRG="true"
subnet=""
vmName="msdocs-linuxVM-$user"
vnetname="msdocs-vnet-$user-$randomIdentifier"
vmImage="Ubuntu2204"
location=""
resourceGroup="msdocs-ubuntu-vm-group1-$RANDOM"
setupFileLocation="resource-metadata.csv"
publicIpSku=""
addressPrefix="10.0.0.0/16"
subnetPrefixes="10.0.0.0/24"
 
# select azure subscription
az account set --subscription $subscriptionID
echo az account set
echo "==========================="
while IFS=, read resourceNo createRG createVnet createVM location user subnet vmImage publicIpSku
do
    echo "resourceNo =" $resourceNo
	echo "createRG = " $createRG
	echo "createVnet = " $createVnet
     if [ "$createRG" == "true" ]; then
        echo "creating RG"
		let "randomIdentifier=$RANDOM*$RANDOM"
		RGname="msdocs-rg-$randomIdentifier"
		    az group create --location $location --name $RGname
        echo rg is done
	 elif [ "$createVnet" == "true" ]; then
	    echo "creating VNet"
            az network vnet create \    
                --name $vnetname \
                --resource-group $resourceGroup \
                --address-prefix $addressPrefix \
                --subnet-name $subnet-$randomIdentifier \
                --subnet-prefixes $subnetPrefixes
     elif [ "$createVM" == "true" ]; then
        echo create the VM
            az vm create \
                --resource-group $resourceGroup \
                --name $vmName \
                --image $vmImage \
                --public-ip-sku $publicIpSku \
                --admin-username $user\
                --admin-password $adminPassword
	 else
		echo "no items created"
	 fi
done < <(tail -n +2 $setupFileLocation)