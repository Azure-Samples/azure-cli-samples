#/bin/bash

# Ensures unique id
random=$(python -c 'import uuid; print(str(uuid.uuid4())[0:8])')

# Variables
resourceGroupName="myResourceGroup$random"
appName="AppServiceMonitor$random"
location="WestUS"

# Create a Resource Group
az group create --name $resourceGroupName --location $location

# Create an App Service Plan
az appservice plan create --name AppServiceMonitorPlan --resource-group $resourceGroupName --location $location

# Create a Web App and save the URL
url=$(az appservice web create --name $appName --plan AppServiceMonitorPlan --resource-group $resourceGroupName --query defaultHostName | sed -e 's/^"//' -e 's/"$//')

# Enable all logging options for the Web App
az appservice web log config --name $appName --resource-group $resourceGroupName --application-logging true --detailed-error-messages true --failed-request-tracing true --web-server-logging filesystem

# Create a Web Server Log
curl -s -L $url/404

# Download the log files for review
az appservice web log download --name $appName --resource-group $resourceGroupName