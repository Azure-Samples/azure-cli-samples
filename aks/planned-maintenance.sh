G=MyResourceGroup
CLUSTER_NAME=myAKSCluster
START_HOUR=1
CONFIG_FILE=./test.json
## Before you begin

# Install the aks-preview extension
az extension add --name aks-preview
## Allow maintenance on every Monday at 1:00am to 2:00am

az aks maintenanceconfiguration add -g $G --cluster-name $CLUSTER_NAME --name default --weekday Monday  --start-hour $START_HOUR
az aks maintenanceconfiguration add -g $G --cluster-name $CLUSTER_NAME --name default --weekday Monday
## Add a maintenance configuration with a JSON file

az aks maintenanceconfiguration add -g $G --cluster-name $CLUSTER_NAME --name default --config-file $CONFIG_FILE
## Update an existing maintenance window

az aks maintenanceconfiguration update -g $G --cluster-name $CLUSTER_NAME --name default --weekday Monday  --start-hour $START_HOUR
## List all maintenance windows in an existing cluster

az aks maintenanceconfiguration list -g $G --cluster-name $CLUSTER_NAME
## Show a specific maintenance configuration window in an AKS cluster

az aks maintenanceconfiguration show -g $G --cluster-name $CLUSTER_NAME --name default
## Delete a certain maintenance configuration window in an existing AKS Cluster

az aks maintenanceconfiguration delete -g $G --cluster-name $CLUSTER_NAME --name default
## Next steps
