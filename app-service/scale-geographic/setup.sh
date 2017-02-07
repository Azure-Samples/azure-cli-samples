#/bin/bash

random=$(python -c 'import uuid; print(str(uuid.uuid4())[0:8])')
resourceGroupName="myResourceGroup$random"
app1Name="AppServiceTM1$random"
app2Name="AppServiceTM2$random"
location1="WestUS"
location2="EastUS"
 
az group create --name $resourceGroupName --location $location1
az network traffic-manager profile create --name $resourceGroupName-tmp --resource-group $resourceGroupName --routing-method Performance --unique-dns-name $resourceGroupName
az appservice plan create --name $app1Name-Plan --resource-group $resourceGroupName --location $location1 --sku S1
az appservice plan create --name $app2Name-Plan --resource-group $resourceGroupName --location $location2 --sku S1

site1=$(az appservice web create --name $app1Name --plan $app1Name-Plan --resource-group $resourceGroupName --query id --output tsv)
site2=$(az appservice web create --name $app2Name --plan $app2Name-Plan --resource-group $resourceGroupName --query id --output tsv)

az network traffic-manager endpoint create -n $app1Name-$location1 --profile-name $resourceGroupName-tmp -g $resourceGroupName --type azureEndpoints --target-resource-id $site1
az network traffic-manager endpoint create -n $app2Name-$location2 --profile-name $resourceGroupName-tmp -g $resourceGroupName --type azureEndpoints --target-resource-id $site2