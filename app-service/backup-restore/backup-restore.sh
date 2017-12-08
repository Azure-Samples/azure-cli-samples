#!/bin/bash

groupname="myResourceGroup"
webappname="<replace-with-your-app-name>"

# List statuses of all backups that are complete or currently executing.
az webapp config backup list --resource-group $groupname --webapp-name $webappname

# Note the backupItemName and storageAccountUrl properties of the backup you want to restore

# Restore the app by overwriting it with the backup data
# Be sure to replace <backupItemName> and <storageAccountUrl>
az webapp config backup restore --resource-group $groupname --webapp-name $webappname \
--backup-name <backupItemName> --container-url <storageAccountUrl> --overwrite
