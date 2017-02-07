#/bin/bash

random=$(python -c 'import uuid; print(str(uuid.uuid4())[0:8])')
resourceGroupName="myResourceGroup$random"
appName="AppServiceMonitor$random"
location="WestUS"

az group create --name $resourceGroupName --location $location
az appservice plan create --name AppServiceMonitorPlan --resource-group $resourceGroupName --location $location
url=$(az appservice web create --name $appName --plan AppServiceMonitorPlan --resource-group $resourceGroupName --query defaultHostName | sed -e 's/^"//' -e 's/"$//')

az appservice web log config --name $appName --resource-group $resourceGroupName --application-logging true --detailed-error-messages true --failed-request-tracing true --web-server-logging filesystem

curl -s -L $url/404

az appservice web log download --name $appName --resource-group $resourceGroupName