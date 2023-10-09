# Azure Container Registry

## Azure CLI sample scripts

The scripts in this directory demonstrate working with [Azure Container Registry][acr-home] using the [Azure CLI][azure-cli] reference commands.

| Script | Description |
| ------ | ----------- |
|**Backup and restore app**||
|[backup-restore.sh][cr-1]|  Creates an App Service app and creates a one-time backup for it, creates a backup schedule for it, and then restores an App Service app from a backup. |
|**Configure app**||
|[configure-custom-domain-webapp-only.sh][cr-2]| Creates an App Service app and maps a custom domain name to it.|
|[configure-ssl-certificate-webapp-only.sh][cr-3]| Creates an App Service app and binds the TLS/SSL certificate of a custom domain name to it.|
|[configure-ssl-certificate.sh][cr-4]| |
|**Connect app to resources**||
|[connect-to-documentdb.sh][cr-5]| Creates an App Service app and an Azure Cosmos DB, then adds the Azure Cosmos DB connection details to the app settings. |
|[connect-to-redis.sh][cr-6]| Creates an App Service app and an Azure Cache for Redis, then adds the redis connection details to the app settings.|
|[connect-to-sql.sh][cr-7]| Creates an App Service app and a database in Azure SQL Database, then adds the database connection string to the app settings. |
|[connect-to-storage.sh][cr-8]| Creates an App Service app and a storage account, then adds the storage connection string to the app settings. |
|**Create app**||
|[deploy-deployment-slot.sh][cr-9]| Creates an App Service app with a deployment slot for staging code changes.|
|[deploy-ftp.sh][cr-10]| Creates an App Service app and deploys a file to it using FTP.|
|[deploy-github.sh][cr-11]| Creates an App Service app and deploys code from a public GitHub repository. |
|[deploy-linux-docker-webapp-only.sh][cr-12]| Creates an App Service app on Linux and loads a Docker image from Docker Hub.|
|[deploy-vsts-continuous-webapp-only.sh][cr-13]| Creates an App Service app with continuous publishing from a GitHub repository you own. |
|[integrate-with-app-gateway.sh][cr-14]| Creates an App Service app and configures code push into a local Git repository.|
|**Monitor app**||
|[monitor-with-logs.sh][cr-15]| Creates an App Service app, enables logging for it, and downloads the logs to your local machine.|
|**Scale app**||
|[scale-geographic.sh][cr-16]| Creates two App Service apps in two different geographical regions and makes them available through a single endpoint using Azure Traffic Manager.|
|[scale-manual.sh][cr-17]| Creates an App Service app and scales it across 2 instances.|




Creates an App Service app and a Private Endpoint

<!-- SCRIPTS -->
[cr-1]: ./backup-one-time-schedule-restore/backup-restore.sh
[cr-2]: ./configure-custom-domain/configure-custom-domain-webapp-only.sh
[cr-3]: ./configure-ssl-certificate/configure-ssl-certificate-webapp-only.sh
[cr-4]: ./configure-ssl-certificate/configure-ssl-certificate.sh
[cr-5]: ./connect-to-documentdb/connect-to-documentdb.sh
[cr-6]: ./connect-to-redis/connect-to-redis.sh
[cr-7]: ./connect-to-sql/connect-to-sql.sh
[cr-8]: ./connect-to-storage/connect-to-storage.sh
[cr-9]: ./deploy-deployment-slot/deploy-deployment-slot.sh
[cr-10]: ./deploy-ftp/deploy-ftp.sh
[cr-11]: ./deploy-github/deploy-github.sh
[cr-12]: ./deploy-linux-docker/deploy-linux-docker-webapp-only.sh
[cr-13]: ./deploy-vsts-continuous/deploy-vsts-continuous-webapp-only.sh
[cr-14]: ./integrate-with-app-gateway/integrate-with-app-gateway.sh
[cr-15]: ./monitor-with-logs/monitor-with-logs.sh
[cr-16]: ./scale-geographic/scale-geographic.sh
[cr-17]: ./scale-manual/scale-manual.sh

<!-- EXTERNAL -->
[acr-home]: https://azure.microsoft.com/services/container-registry/
[azure-cli]: https://learn.microsoft.com/en-us/cli/azure/
