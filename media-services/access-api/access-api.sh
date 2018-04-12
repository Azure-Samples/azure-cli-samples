#!/bin/bash

# Variables

resourceGroupName='amsResourceGroup'
mediaServicesAccountName='juliakoamsaccountname'

az ams  sp create --account-name mediaServicesAccountName \
--resource-group resourceGroupName
