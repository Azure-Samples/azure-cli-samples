---
page_type: sample
languages:
- azurecli
products:
- azure
- azure-cli
- azure-app-service
name: Azure App Service sample scripts
url-fragment:
description: These scripts demonstrate how to work with Azure App Service using the Azure CLI
---
# Azure App Service

## Azure CLI sample scripts

The scripts in this directory demonstrate working with [Azure App Service][aas-home] using the [Azure CLI reference commands][azure-cli].

| Script | Description |
| ------ | ----------- |
|**Backup and restore app**||
|[backup-restore.sh][aas-1]|  Creates an App Service app and creates a one-time backup for it, creates a backup schedule for it, and then restores an App Service app from a backup. |
|**Configure app**||
|[configure-custom-domain-webapp-only.sh][aas-2]| Creates an App Service app and maps a custom domain name to it.|
|[configure-ssl-certificate-webapp-only.sh][aas-3]| Creates an App Service app and binds the TLS/SSL certificate of a custom domain name to it.|
|[configure-ssl-certificate.sh][aas-4]| | Creates an App Service app
|**Connect app to resources**||
|[connect-to-documentdb.sh][aas-5]| Creates an App Service app and an Azure Cosmos DB, then adds the Azure Cosmos DB connection details to the app settings. |
|[connect-to-redis.sh][aas-6]| Creates an App Service app and an Azure Cache for Redis, then adds the redis connection details to the app settings.|
|[connect-to-sql.sh][aas-7]| Creates an App Service app and a database in Azure SQL Database, then adds the database connection string to the app settings. |
|[connect-to-storage.sh][aas-8]| Creates an App Service app and a storage account, then adds the storage connection string to the app settings. |
|**Create app**||
|[deploy-deployment-slot.sh][aas-9]| Creates an App Service app with a deployment slot for staging code changes.|
|[deploy-ftp.sh][aas-10]| Creates an App Service app and deploys a file to it using FTP.|
|[deploy-github.sh][aas-11]| Creates an App Service app and deploys code from a public GitHub repository. |
|[deploy-linux-docker-webapp-only.sh][aas-12]| Creates an App Service app on Linux and loads a Docker image from Docker Hub.|
|[deploy-vsts-continuous-webapp-only.sh][aas-13]| Creates an App Service app with continuous publishing from a GitHub repository you own. |
|[integrate-with-app-gateway.sh][aas-14]| Creates an App Service app and configures code push into a local Git repository.|
|**Monitor app**||
|[monitor-with-logs.sh][aas-15]| Creates an App Service app, enables logging for it, and downloads the logs to your local machine.|
|**Scale app**||
|[scale-geographic.sh][aas-16]| Creates two App Service apps in two different geographical regions and makes them available through a single endpoint using Azure Traffic Manager.|
|[scale-manual.sh][aas-17]| Creates an App Service app and scales it across 2 instances.|

<!-- SCRIPTS -->
[aas-1]: ./backup-one-time-schedule-restore/backup-restore.sh
[aas-2]: ./configure-custom-domain/configure-custom-domain-webapp-only.sh
[aas-3]: ./configure-ssl-certificate/configure-ssl-certificate-webapp-only.sh
[aas-4]: ./configure-ssl-certificate/configure-ssl-certificate.sh
[aas-5]: ./connect-to-documentdb/connect-to-documentdb.sh
[aas-6]: ./connect-to-redis/connect-to-redis.sh
[aas-7]: ./connect-to-sql/connect-to-sql.sh
[aas-8]: ./connect-to-storage/connect-to-storage.sh
[aas-9]: ./deploy-deployment-slot/deploy-deployment-slot.sh
[aas-10]: ./deploy-ftp/deploy-ftp.sh
[aas-11]: ./deploy-github/deploy-github.sh
[aas-12]: ./deploy-linux-docker/deploy-linux-docker-webapp-only.sh
[aas-13]: ./deploy-vsts-continuous/deploy-vsts-continuous-webapp-only.sh
[aas-14]: ./integrate-with-app-gateway/integrate-with-app-gateway.sh
[aas-15]: ./monitor-with-logs/monitor-with-logs.sh
[aas-16]: ./scale-geographic/scale-geographic.sh
[aas-17]: ./scale-manual/scale-manual.sh

<!-- EXTERNAL -->
[aas-home]: https://azure.microsoft.com/services/container-registry/
[azure-cli]: https://learn.microsoft.com/en-us/cli/azure/reference-index
