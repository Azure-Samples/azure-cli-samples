## Before you begin

# Install the aks-preview extension
az extension add --name aks-preview
## Allow maintenance on every Monday at 1:00am to 2:00am

az aks maintenanceconfiguration add -g MyResourceGroup --cluster-name myAKSCluster --name default --weekday Monday  --start-hour 1
az aks maintenanceconfiguration add -g MyResourceGroup --cluster-name myAKSCluster --name default --weekday Monday
## Add a maintenance configuration with a JSON file

az aks maintenanceconfiguration add -g MyResourceGroup --cluster-name myAKSCluster --name default --config-file ./test.json
## Update an existing maintenance window

az aks maintenanceconfiguration update -g MyResourceGroup --cluster-name myAKSCluster --name default --weekday Monday  --start-hour 1
## List all maintenance windows in an existing cluster

az aks maintenanceconfiguration list -g MyResourceGroup --cluster-name myAKSCluster
## Show a specific maintenance configuration window in an AKS cluster

az aks maintenanceconfiguration show -g MyResourceGroup --cluster-name myAKSCluster --name default
## Delete a certain maintenance configuration window in an existing AKS Cluster

az aks maintenanceconfiguration delete -g MyResourceGroup --cluster-name myAKSCluster --name default
## Next steps
