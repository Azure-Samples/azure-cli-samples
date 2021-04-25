$RESOURCE_GROUP_NAME=""
$CLUSTER_NAME=""
## Before you begin

## AKS certificates, Certificate Authorities, and Service Accounts

## Rotate your cluster certificates

az aks get-credentials -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME
az aks rotate-certs -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME
az aks get-credentials -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME
## Next steps
