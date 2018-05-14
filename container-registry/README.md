# Azure Container Registry

## Azure CLI sample scripts

The scripts in this directory demonstrate working with [Azure Container Registry][acr-home] using the [Azure CLI][azure-cli].

| Script | Description |
| ------ | ----------- |
|[service-principal-assign-role.sh][sp-assign]| Assigns a role to an existing Azure Active Directory service principal, granting the service principal access to an Azure Container Registry. |
|[service-principal-create.sh][sp-create]| Creates a new Azure Active Directory service principal with permissions to an Azure Container Registry. |

<!-- SCRIPTS -->
[sp-assign]: ./service-principal-assign-role/service-principal-assign-role.sh
[sp-create]: ./service-principal-create/service-principal-create.sh

<!-- EXTERNAL -->
[acr-home]: https://azure.microsoft.com/services/container-registry/
[azure-cli]: https://docs.microsoft.com/cli/azure/overview
