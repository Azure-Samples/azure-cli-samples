#/bin/bash
# Passed validation in Cloud Shell on 5/3/2022
# Code blocks for ../azure-monitor/logs/azure-cli-log-analytics-workspace-sample.md
# <FullScript>
# Managing Azure Monitor Logs
# set -e # exit if error
# Variable block
# <variable>
resourceGroup=resourceGroup$RANDOM
# </variable>
# <creategroup>
az group create --name $resourceGroup --location eastus
# </creategroup>
# <workspace>
az monitor log-analytics workspace create --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace
# </workspace>
# <listtables>
az monitor log-analytics workspace table list --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --output table
# </listtables>
# <retention>
az monitor log-analytics workspace table update --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name Syslog --retention-time 45
# </retention>
# <delete>
subscriptionId="$(az account show --query id -o tsv)"
az monitor log-analytics workspace table delete \
   –subscription $subscriptionId --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name MySearchTable_SRCH
# </delete>
# <export>
az monitor log-analytics workspace data-export create --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name DataExport --table Syslog \
   --destination /subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/exportaccount \
   --enable# </export>
# </export>
# <listexport>
az monitor log-analytics workspace data-export list --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --output table
# </listexport>
# <deleteexport>
az monitor log-analytics workspace data-export delete --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name DataExport --yes
# </deleteexport>
# <linked>
az monitor log-analytics workspace linked-service create --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name linkedautomation \
   --resource-id /subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/ContosoWebApp09

az monitor log-analytics workspace linked-service list --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace
# </linked>
# <removelink>
az monitor log-analytics workspace linked-service delete --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name linkedautomation
# </removelink>
# <managestorage>
az monitor log-analytics workspace linked-storage create --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace \
   --storage-accounts /subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/contosostorage \
   --type Alerts

az monitor log-analytics workspace linked-storage list --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --output table
# </managestorage>
# <removestoragelink>
az monitor log-analytics workspace linked-storage delete --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --type Alerts
# </removestoragelink>
# <intelligentpacks>
az monitor log-analytics workspace pack list --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace
# </intelligentpacks>
# <enablepack>
az monitor log-analytics workspace pack enable --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name NetFlow

az monitor log-analytics workspace pack disable --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name NetFlow
# </enablepack>
# <managesaved>
az monitor log-analytics workspace saved-search create --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name SavedSearch01 \
   --category "Log Management" --display-name SavedSearch01 \
   --saved-query "AzureActivity | summarize count() by bin(TimeGenerated, 1h)" --fa Function01 --fp "a:string = value"
# </managesaved>
# <viewsaved>
az monitor log-analytics workspace saved-search show --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name SavedSearch01
az monitor log-analytics workspace saved-search list --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace
# </viewsaved>
# <deletesaved>
az monitor log-analytics workspace saved-search delete --resource-group $resourceGroup \
   --workspace-name ContosoWorkspace --name SavedSearch01 --yes
# </deletesaved>
# </FullScript>

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y