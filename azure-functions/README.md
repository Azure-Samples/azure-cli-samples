---
page_type: sample
languages:
- azurecli
products:
- azure
- azure-clis
- azure-functions
name: Azure Functions sample scripts
url-fragment: 
description: These scripts demonstrate how to create and manage Azure Functions resources using the Azure CLI.
---
# Azure Functions: Azure CLI sample scripts

These end-to-end Azure CLI scripts help you learn how to provision and manage the Azure resources required by Azure Functions. You must use the [Azure Functions Core Tools][func-core-tools] to create actual Azure Functions code projects from the command line on your local computer and deploy code to these Azure resources.

For a complete end-to-end example of developing and deploying from the command line using both Core Tools and the Azure CLI, see one of these language-specific [command line quickstarts][func-quickstart].

The scripts in this directory demonstrate working with [Azure Functions][func-home] using the [Azure CLI reference commands][azure-cli].

## Prerequisites

- An Azure account with an active subscription. [Create an account for free](https://azure.microsoft.com/free/?ref=microsoft.com&utm_source=microsoft.com&utm_medium=docs&utm_campaign=visualstudio).

- Use the Bash environment in [Azure Cloud Shell](https://learn.microsoft.com/azure/cloud-shell/overview). Cloud Shell has the Azure CLI and required tools like `jq` preinstalled. You can [open Cloud Shell in a new window](https://shell.azure.com).

- If you prefer to run the scripts locally, [install the Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (version 2.64 or later) and sign in with [az login](https://learn.microsoft.com/cli/azure/reference-index#az-login). You also need [jq](https://jqlang.github.io/jq/download/) installed for the Flex Consumption scripts that parse JSON output.

## Run a script

Each script is self-contained and uses random identifiers to create uniquely named resources. To run a script:

1. Open Azure Cloud Shell or your local Bash terminal signed in to Azure.
1. Navigate to the folder that contains the script you want to run.
1. Run the script directly:

    ```bash
    bash <script-name>.sh
    ```

The scripts set variables at the top for resource names, locations, and SKUs. You can modify these before running.

## Clean up resources

Every script creates resources in a new resource group. After you're done, you can delete all the resources created by a script by deleting its resource group:

```azurecli
az group delete --name $resourceGroup --yes --no-wait
```

Each script also includes a commented-out cleanup command at the end that you can uncomment to enable automatic cleanup.

## Sample scripts

| Script | Description |
| ------ | ----------- |
|**Create a function app**||
|[create-function-app-flex-consumption.sh][af-1]| Creates a function app in a [Flex Consumption plan][plan-flex] with a user-assigned managed identity. **This is the recommended serverless hosting plan.** |
|[create-function-app-consumption.sh][af-2]| Creates a function app in a [Consumption plan][plan-consumption]. |
|[create-function-app-premium-plan.sh][af-3]| Creates a function app in a [Premium (Elastic Premium) plan][plan-premium]. |
|[create-function-app-app-service-plan.sh][af-4]| Creates a function app in a dedicated [App Service plan][plan-dedicated]. |
|**Connect to services**||
|[create-function-app-connect-to-storage-account.sh][af-5]| Creates a function app in a [Flex Consumption plan][plan-flex] and connects it to a storage account using managed identity. |
|[create-function-app-connect-to-cosmos-db.sh][af-6]| Creates a function app in a [Flex Consumption plan][plan-flex] and connects it to Azure Cosmos DB using managed identity and RBAC. |
|[connect-azure-openai-resources.sh][af-7]| Creates a function app in a [Flex Consumption plan][plan-flex] and connects it to Azure OpenAI using managed identity. |
|[functions-cli-mount-files-storage-linux.sh][af-8]| Creates a Linux function app and mounts an Azure Files share, which lets you leverage existing data or machine learning models in your functions. |
|**Secure networking**||
|[create-function-app-vnet-storage.sh][af-10]| Creates a function app in a [Flex Consumption plan][plan-flex] with VNet integration and restricts the storage account behind private endpoints so it's only accessible from inside the virtual network. |
|[create-function-app-private-endpoint.sh][af-11]| Creates a function app in a [Flex Consumption plan][plan-flex] with an inbound private endpoint, restricting the function app's HTTP endpoints to only be callable from inside the virtual network. |
|**Deploy code**||
|[deploy-function-app-with-function-github-continuous.sh][af-9]| Creates a function app in a [Consumption plan][plan-consumption] and deploys code from a public GitHub repository. |

<!-- SCRIPTS -->
[af-1]: ./create-function-app-flex-consumption/create-function-app-flex-consumption.sh
[af-2]: ./create-function-app-consumption/create-function-app-consumption.sh
[af-3]: ./create-function-app-premium-plan/create-function-app-premium-plan.sh
[af-4]: ./create-function-app-app-service-plan/create-function-app-app-service-plan.sh
[af-5]: ./create-function-app-connect-to-storage/create-function-app-connect-to-storage-account.sh
[af-6]: ./create-function-app-connect-to-cosmos-db/create-function-app-connect-to-cosmos-db.sh
[af-7]: ./connect-azure-openai-resources/connect-azure-openai-resources.sh
[af-8]: ./functions-cli-mount-files-storage-linux/functions-cli-mount-files-storage-linux.sh
[af-9]: ./deploy-function-app-with-function-github-continuous/deploy-function-app-with-function-github-continuous.sh
[af-10]: ./create-function-app-vnet-storage/create-function-app-vnet-storage.sh
[af-11]: ./create-function-app-private-endpoint/create-function-app-private-endpoint.sh

<!-- EXTERNAL -->
[func-home]: https://learn.microsoft.com/azure/azure-functions/
[func-core-tools]: https://learn.microsoft.com/azure/azure-functions/functions-run-local
[func-quickstart]: https://learn.microsoft.com/azure/azure-functions/how-to-create-function-azure-cli
[azure-cli]: https://learn.microsoft.com/cli/azure/reference-index
[plan-flex]: https://learn.microsoft.com/azure/azure-functions/flex-consumption-plan
[plan-consumption]: https://learn.microsoft.com/azure/azure-functions/consumption-plan
[plan-premium]: https://learn.microsoft.com/azure/azure-functions/functions-premium-plan
[plan-dedicated]: https://learn.microsoft.com/azure/azure-functions/dedicated-plan

## CLI command reference

The following table lists the Azure CLI commands used across these sample scripts.

### Resource management

| Command | Notes |
|---|---|
| [az group create](https://learn.microsoft.com/cli/azure/group#az-group-create) | Creates a resource group to contain all script resources. |
| [az group delete](https://learn.microsoft.com/cli/azure/group#az-group-delete) | Deletes a resource group and all contained resources. |

### Storage

| Command | Notes |
|---|---|
| [az storage account create](https://learn.microsoft.com/cli/azure/storage/account#az-storage-account-create) | Creates an Azure Storage account. |
| [az storage account show](https://learn.microsoft.com/cli/azure/storage/account#az-storage-account-show) | Gets storage account details, including the resource ID for role assignments. |
| [az storage account update](https://learn.microsoft.com/cli/azure/storage/account#az-storage-account-update) | Updates storage account properties, such as disabling public network access. |
| [az storage share create](https://learn.microsoft.com/cli/azure/storage/share#az-storage-share-create) | Creates a file share in Azure Files. |
| [az storage directory create](https://learn.microsoft.com/cli/azure/storage/directory#az-storage-directory-create) | Creates a directory in an Azure Files share. |

### Function apps

| Command | Notes |
|---|---|
| [az functionapp create](https://learn.microsoft.com/cli/azure/functionapp#az-functionapp-create) | Creates a function app in a Consumption, Flex Consumption, Premium, or Dedicated plan. |
| [az functionapp plan create](https://learn.microsoft.com/cli/azure/functionapp/plan#az-functionapp-plan-create) | Creates a Premium or App Service hosting plan for a function app. |
| [az functionapp config appsettings set](https://learn.microsoft.com/cli/azure/functionapp/config/appsettings#az-functionapp-config-appsettings-set) | Creates or updates application settings in a function app. |
| [az functionapp config appsettings delete](https://learn.microsoft.com/cli/azure/functionapp/config/appsettings#az-functionapp-config-appsettings-delete) | Removes application settings from a function app. |
| [az functionapp show](https://learn.microsoft.com/cli/azure/functionapp#az-functionapp-show) | Gets the details of a function app, including the resource ID. |

### Identity and access

| Command | Notes |
|---|---|
| [az identity create](https://learn.microsoft.com/cli/azure/identity#az-identity-create) | Creates a user-assigned managed identity. |
| [az identity show](https://learn.microsoft.com/cli/azure/identity#az-identity-show) | Gets the properties of a managed identity, including the client ID. |
| [az role assignment create](https://learn.microsoft.com/cli/azure/role/assignment#az-role-assignment-create) | Assigns an Azure RBAC role to a managed identity or user account. |
| [az ad signed-in-user show](https://learn.microsoft.com/cli/azure/ad/signed-in-user#az-ad-signed-in-user-show) | Gets the object ID of the current signed-in Azure account. |

### Monitoring

| Command | Notes |
|---|---|
| [az monitor app-insights component show](https://learn.microsoft.com/cli/azure/monitor/app-insights/component#az-monitor-app-insights-component-show) | Gets the Application Insights resource for a function app. |
| [az extension add](https://learn.microsoft.com/cli/azure/extension#az-extension-add) | Installs CLI extensions, such as the `application-insights` extension. |

### Azure Cosmos DB

| Command | Notes |
|---|---|
| [az cosmosdb create](https://learn.microsoft.com/cli/azure/cosmosdb#az-cosmosdb-create) | Creates an Azure Cosmos DB account. |
| [az cosmosdb show](https://learn.microsoft.com/cli/azure/cosmosdb#az-cosmosdb-show) | Gets account details, including the document endpoint. |
| [az cosmosdb sql database create](https://learn.microsoft.com/cli/azure/cosmosdb/sql/database#az-cosmosdb-sql-database-create) | Creates a database in a Cosmos DB account. |
| [az cosmosdb sql container create](https://learn.microsoft.com/cli/azure/cosmosdb/sql/container#az-cosmosdb-sql-container-create) | Creates a container in a Cosmos DB SQL database. |
| [az cosmosdb sql role assignment create](https://learn.microsoft.com/cli/azure/cosmosdb/sql/role/assignment#az-cosmosdb-sql-role-assignment-create) | Assigns a Cosmos DB data-plane RBAC role to a principal. |

### Azure OpenAI

| Command | Notes |
|---|---|
| [az cognitiveservices account create](https://learn.microsoft.com/cli/azure/cognitiveservices/account#az-cognitiveservices-account-create) | Creates an Azure OpenAI (Cognitive Services) resource. |

### Networking

| Command | Notes |
|---|---|
| [az network vnet create](https://learn.microsoft.com/cli/azure/network/vnet#az-network-vnet-create) | Creates a virtual network. |
| [az network vnet subnet create](https://learn.microsoft.com/cli/azure/network/vnet/subnet#az-network-vnet-subnet-create) | Creates a subnet, optionally with a delegation for Functions VNet integration. |
| [az network private-endpoint create](https://learn.microsoft.com/cli/azure/network/private-endpoint#az-network-private-endpoint-create) | Creates a private endpoint for a storage account or function app. |
| [az network private-dns zone create](https://learn.microsoft.com/cli/azure/network/private-dns/zone#az-network-private-dns-zone-create) | Creates a private DNS zone for private endpoint name resolution. |
| [az network private-dns link vnet create](https://learn.microsoft.com/cli/azure/network/private-dns/link/vnet#az-network-private-dns-link-vnet-create) | Links a private DNS zone to a virtual network. |
| [az network private-endpoint dns-zone-group create](https://learn.microsoft.com/cli/azure/network/private-endpoint/dns-zone-group#az-network-private-endpoint-dns-zone-group-create) | Configures a private endpoint to register DNS records in a private DNS zone. |
| [az resource update](https://learn.microsoft.com/cli/azure/resource#az-resource-update) | Updates a resource property, such as disabling public network access on a function app. |

## Other resources

- [Azure Functions documentation](https://learn.microsoft.com/azure/azure-functions/)
- [Azure Functions Core Tools reference](https://learn.microsoft.com/azure/azure-functions/functions-run-local)
- [Azure CLI documentation](https://learn.microsoft.com/cli/azure/)
- [Create your first function from the command line](https://learn.microsoft.com/azure/azure-functions/how-to-create-function-azure-cli)
