# Azure Container Registry

## Azure CLI sample scripts

The scripts in this directory demonstrate working with [Azure Container Registry][acr-home] using the [Azure CLI][azure-cli] reference commands.

| Script | Description |
| ------ | ----------- |
|[backup-restore.sh][cr-1]| Creates a new Azure Active Directory service principal with permissions to an Azure Container Registry. |
|[configure-custom-domain-webapp-only.sh][cr-2]| |
|[configure-ssl-certificate-webapp-only.sh][cr-3]| |
|[configure-ssl-certificate.sh][cr-4]| |
|[connect-to-documentdb.sh][cr-5]| |
|[connect-to-redis.sh][cr-6]| |
|[connect-to-sql.sh][cr-7]| |
|[connect-to-storage.sh][cr-8]| |
|[deploy-deployment-slot.sh][cr-9]| |
|[deploy-ftp.sh][cr-10]| |
|[deploy-github.sh][cr-11]| |
|[deploy-linux-docker-webapp-only.sh][cr-12]| |
|[deploy-vsts-continuous-webapp-only.sh][cr-13]| |
|[integrate-with-app-gateway.sh][cr-14]| |
|[monitor-with-logs.sh][cr-15]| |
|[scale-geographic.sh][cr-16]| |
|[scale-manual.sh][cr-17]| |

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
