#/bin/bash

# Ensures unique id
random=$(python -c 'import uuid; print(str(uuid.uuid4())[0:8])')

# Variables
appName="webappwithSQL$random"
serverName="webappwithsql$random"
location="WestUS"
startip="0.0.0.0"
endip="0.0.0.0"
username="<replace-with-username>"
sqlServerPassword="<replace-with-password>"

# Create a Resource Group 
az group create --name myResourceGroup --location $location

# Create an App Service Plan
az appservice plan create --name WebAppWithSQLPlan --resource-group myResourceGroup --location $location

# Create a Web App
az appservice web create --name $appName --plan WebAppWithSQLPlan --resource-group myResourceGroup

# Create a SQL Server
az sql server create --name $serverName --resource-group myResourceGroup --location $location --administrator-login $username --administrator-login-password $sqlServerPassword

# Configure Firewall for Azure Access
az sql server firewall create --resource-group myResourceGroup --server-name $serverName --name AllowYourIp --start-ip-address $startip --end-ip-address $endip

# Create Database on Server
az sql db create --resource-group myResourceGroup -l $location --server-name $serverName --name MySampleDatabase --requested-service-objective-name S0

# Assign the connection string to an App Setting in the Web App
az appservice web config appsettings update --settings "SQLSRV_CONNSTR=Server=tcp:$serverName.database.windows.net;Database=MySampleDatabase;User ID=$username@$serverName;Password=$sqlServerPassword;Trusted_Connection=False;Encrypt=True;" --name $appName --resource-group myResourceGroup