---
page_type: sample
languages:
- azurecli
products:
- azure
- azure-cli
- azure-functions
name: Azure Functions sample scripts
url-fragment:
description: These scripts demonstrate how to create and manage Azure Functions resources using the Azure CLI.
---
# Azure Functions

## Azure CLI sample scripts

These end-to-end Azure CLI scripts help you learn how to provision and manage the Azure resources required by Azure Functions. You must use the [Azure Functions Core Tools][func-core-tools] to create actual Azure Functions code projects from the command line on your local computer and deploy code to these Azure resources.

For a complete end-to-end example of developing and deploying from the command line using both Core Tools and the Azure CLI, see one of these language-specific [command line quickstarts][func-quickstart].

The scripts in this directory demonstrate working with [Azure Functions][func-home] using the [Azure CLI reference commands][azure-cli].

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

<!-- EXTERNAL -->
[func-home]: https://learn.microsoft.com/azure/azure-functions/
[func-core-tools]: https://learn.microsoft.com/azure/azure-functions/functions-run-local
[func-quickstart]: https://learn.microsoft.com/azure/azure-functions/how-to-create-function-azure-cli
[azure-cli]: https://learn.microsoft.com/cli/azure/reference-index
[plan-flex]: https://learn.microsoft.com/azure/azure-functions/flex-consumption-plan
[plan-consumption]: https://learn.microsoft.com/azure/azure-functions/consumption-plan
[plan-premium]: https://learn.microsoft.com/azure/azure-functions/functions-premium-plan
[plan-dedicated]: https://learn.microsoft.com/azure/azure-functions/dedicated-plan
