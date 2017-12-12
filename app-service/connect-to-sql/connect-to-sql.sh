#/bin/bash

# Variables
appName="webappwithSQL$RANDOM"
serverName="webappwithsql$RANDOM"
location="WestUS"
startip="0.0.0.0"
endip="0.0.0.0"
username="<replace-with-username>"
sqlServerPassword="<replace-with-password>"

# Create a resource group 
az group create --name myResourceGroup --location $location

# Create an App Service plan
az appservice plan create --name myAppServicePlan --resource-group myResourceGroup \
--location $location

# Create a web app
az webapp create --name $appName --plan myAppServicePlan --resource-group myResourceGroup

# Create a SQL Database server
az sql server create --name $serverName --resource-group myResourceGroup \
--location $location --admin-user $username --admin-password $sqlServerPassword

# Configure firewall for Azure access
az sql server firewall-rule create --server $serverName --resource-group myResourceGroup \
--name AllowYourIp --start-ip-address $startip --end-ip-address $endip

# Create a database called 'MySampleDatabase' on server
az sql db create --server $serverName --resource-group myResourceGroup --name MySampleDatabase \
--service-objective S0

# Get connection string for the database
connstring=$(az sql db show-connection-string --name MySampleDatabase --server $serverName \
--client ado.net --output tsv)

# Add credentials to connection string
connstring=${connstring//<username>/$username}
connstring=${connstring//<password>/$sqlServerPassword}

# Assign the connection string to an app setting in the web app
az webapp config appsettings set --name $appName --resource-group myResourceGroup \
--settings "SQLSRV_CONNSTR=$connstring" 
