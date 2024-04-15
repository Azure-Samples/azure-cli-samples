#!/bin/bash

# Passed validation in Azure Cloud Shell Bash environment on 4/25/2022

# <FullScript>

# One sentence script description here

#

# Scripts steps expalined here

# ...

# Finally, it ...

#

# set -e # exit if error

# Variable block


Identifier="0"

user="john"

createvm="true"

vmName="linuxVM-$user"

vmImage="Ubuntu2204"

location="westus"

resourceGroup="ubuntu-vm-group22-$Identifier"

# task 1 create resources

for i in $(seq 0 1);
do
    Identifier=$((Identifier+1))
    echo "creating task $Identifier that creates a [resource group]"

    echo random $Identifier

    resourceGroup="ubuntu-vm-group22-$Identifier"

    az group create --l $location -n $resourceGroup

    echo $Identifier

    # read in commands from csv file

    echo read in commands from csv file

    c1= sed -n "$Identifier"p file.csv

    echo test echo

    if "$createvm" =true; then 

        echo loop
        az vm create \
            --resource-group $resourceGroup \
            --name $vmName \
            --image $vmImage \
            --public-ip-sku Standard \
            --admin-username $user\
            --admin-password qwertY123456  
    fi
    az group delete -n $resourceGroup -y

    echo deleted $resourceGroup

    done 2>&1 >> output.txt
echo done