# Create a resource group.
az group create --name myResourceGroup --location westus

# Create an Azure Container Registry.
az acr create --name <registry_name> --resource-group myResourceGroup --location westus --sku basic --admin-enabled true --query loginServer --output tsv

# Show ACR credentials.
az acr credential show --name <registry_name> --resource-group myResourceGroup --query [username,passwords[?name=='password'].value] --output tsv

# Before continuing, save the ACR credentials and registry URL. You will need this information in the commands below.

# Pull from Docker.
docker login <acr_registry_name>.azurecr.io -u <registry_user>
docker pull <registry_user/container_name:version>

# Tag Docker image.
docker tag <registry_user/container_name:version> <acr_registry_name>.azurecr.io/<container_name:version>

# Push container image to Azure Container Registry.
docker push <acr_registry_name>.azurecr.io/<container_name:version>

# Create an App Service plan.
az appservice plan create --name AppServiceLinuxDockerPlan --resource-group myResourceGroup --location westus --is-linux --sku S1

# Create a web app.
az webapp create --name <app_name> --plan AppServiceLinuxDockerPlan --resource-group myResourceGroup --deployment-container-image-name <acr_registry_name>.azurecr.io/<container_name:version>

# Configure web app with a custom Docker Container from Azure Container Registry.
az webapp config container set --resource-group myResourceGroup --name <app_name> --docker-registry-server-url http://<acr_registry_name>.azurecr.io --docker-registry-server-user <registry_user> --docker-registry-server-password <registry_password>
