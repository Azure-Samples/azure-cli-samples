#!/bin/bash

# Update the following variables for your own settings:
resourceGroup=build2018
amsAccountName=build18
amsSPName=build2018demo

# Reset your account credentials and get the app.config settings back
az ams account sp reset-credentials \
  --account-name $amsAccountName \
  --name $amsSPName \
  --resource-group $resourceGroup \
  --role Owner \
  --xml \
  --years 2 \

echo "press  [ENTER]  to continue."
read continue