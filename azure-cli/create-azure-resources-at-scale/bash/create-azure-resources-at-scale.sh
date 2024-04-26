#!/bin/bash
# Passed validation in Azure Cloud Shell Bash environment on 4/25/2022

# <FullScript>
# Create Azure resources at scale
#
# This sample script creates a multiple Azure Virtual Machines from a CSV file 
# containg dependent resource flags and parameter properties. It also logs
# the progress of each loop to a local TXT file.
#
# set -e # exit if error
# Variable block
# Replace these parameter values with real values
subscriptionID="00000000-0000-0000-0000-00000000"
setupFileLocation="C:\myPath\myFileName"
addressPrefix="10.0.0.0/16"
subnetPrefixes="10.0.0.0/24"
randomIdentifier="$RANDOM*$RANDOM"

# These parameter values are overwritten by values received from the CSV setup file.
# These parameters are placeholders. Do not delete them.
lineCounter="0"
createvm=""
createvnet=""
createrg=""
location=""
resourceGroup=""
user=""
adminPassword=""
subnet=""
vmName=""
vnetname=""
vmImage=""
publicIpSku=""


# set your Azure subscription
az account set --subscription "$subscriptionID"

# </FullScript>
