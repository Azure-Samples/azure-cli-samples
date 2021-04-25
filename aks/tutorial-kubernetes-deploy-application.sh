RESOURCE_GROUP=myResourceGroup
## Before you begin

## Update the manifest file

az acr list --resource-group $RESOURCE_GROUP --query "[].{acrLoginServer:loginServer}" --output table
## Deploy the application

## Test the application

## Next steps
