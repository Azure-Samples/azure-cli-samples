NAME="myApp"
ROLE=contributor
SCOPES=/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>
## Prerequisites 

## Workflow file overview

## Create a service principal

az ad sp create-for-rbac --name $NAME --role $ROLE --scopes $SCOPES
## Configure the GitHub secrets

##  Build a container image and deploy to Azure Kubernetes Service cluster

## Clean up resources

## Next steps
