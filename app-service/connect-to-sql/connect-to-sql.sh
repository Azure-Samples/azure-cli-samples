#/bin/bash
# Passed validation in Cloud Shell on 4/25/2022

# <FullScript>
# Connect an App Service app to SQL Database
#
# This sample script creates a database in Azure SQL Database
# and an App Service app. It then links the database to the app
# using app settings.
#
# set -e # exit if error
# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-app-service-rg-$randomIdentifier"
tag="connect-to-sql.sh"
appServicePlan="msdocs-app-service-plan-$randomIdentifier"
webapp="msdocs-web-app-$randomIdentifier"
server="msdocs-azuresql-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="azureuser"
password="Pa$$w0rD-$randomIdentifier"
startIp="0.0.0.0"
endIp="0.0.0.0"

# Create a resource group.
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tag $tag

# Create an App Service Plan
echo "Creating $appServicePlan"
az appservice plan create --name $appServicePlan --resource-group $resourceGroup \
--location "$location"

# Create a Web App
echo "Creating $webapp"
az webapp create --name $webapp --plan $appServicePlan --resource-group $resourceGroup 

# Create a SQL Database server
echo "Creating $server"
az sql server create --name $server --resource-group $resourceGroup --location "$location" --admin-user $login --admin-password $password

# Configure firewall for Azure access
echo "Creating firewall rule with starting ip of $startIp" and ending ip of $endIp
az sql server firewall-rule create \
--server $server \
--resource-group $resourceGroup \
--name AllowYourIp \
--start-ip-address $startIp --end-ip-address $endIp

# Create a database called 'MySampleDatabase' on server
echo "Creating $database"
az sql db create --server $server \
 --resource-group $resourceGroup --name $database \
--service-objective S0

# Get connection string for the database
connstring=$(az sql db show-connection-string --name $database --server $server \
--client ado.net --output tsv)

# Add credentials to connection string
connstring=${connstring//<username>/$login}
connstring=${connstring//<password>/$password}

# Assign the connection string to an app setting in the web app
az webapp config appsettings set --name $webapp \
--resource-group $resourceGroup \
--settings "SQLSRV_CONNSTR=$connstring" 
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
