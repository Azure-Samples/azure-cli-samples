#!/usr/bin/env bash
set -e

DEFAULT_TAG='restart-tag'
LOCATION='westus'
TAG=${1:-$DEFAULT_TAG}

RESOURCE_GROUPS=('GROUP1' 'GROUP2' 'GROUP3')

for group in ${RESOURCE_GROUPS[@]}; do
    # Create the resource group if it doesn't exist
    echo "Creating resource group ${group} in ${LOCATION}"
    az group create -n ${group} -l ${LOCATION} 1>/dev/null

    echo "Deploying vm named ${group}-vm in ${group} with no waiting"
    az vm create -g ${group} -n "${group}-vm" --image UbuntuLTS --admin-username deploy --tags ${DEFAULT_TAG} --no-wait $1>/dev/null
    # If you don't have an ssh key, you can add the --generate-ssh-keys parameter to the az vm create command
    # az vm create -g ${group} -n "${group}-vm" --image UbuntuLTS --admin-username deploy --tags ${DEFAULT_TAG} --generate-ssh-keys --no-wait $1>/dev/null
done

echo "Waiting for the vms to complete provisioning"

GROUP_QUERY=''
for group in ${RESOURCE_GROUPS[@]}; do
    if [[ ${GROUP_QUERY} ]]; then
        GROUP_QUERY="${GROUP_QUERY} || resourceGroup=='${group}'"
    else
        GROUP_QUERY="[?resourceGroup=='${group}'"
    fi
done

SUCCESS_GROUP_QUERY="length(${GROUP_QUERY}] | [?provisioningState=='Succeeded'])"
FAILED_GROUP_QUERY="length(${GROUP_QUERY}] | [?provisioningState=='Failed'])"

echo ""
while [[ $(az vm list --query "${SUCCESS_GROUP_QUERY}") != ${#RESOURCE_GROUPS[@]} ]]; do
    echo "Still not provisioned. Sleeping for 20 seconds."
    sleep 20
    if [[ $(az vm list --query "${FAILED_GROUP_QUERY}") != 0 ]]; then
        echo "At least one of the vms failed to provision successfully!!"
        exit 1
    fi
done

echo ""
echo "Restarting virtual machines with ids via the group query"
az vm restart --ids $(az vm list --query "join(' ', ${GROUP_QUERY}] | [].id)" -o tsv) $1>/dev/null

echo ""
echo "Restarting virtual machines with a given tag"
az vm restart --ids $(az resource list --tag ${TAG} --query "[?type=='Microsoft.Compute/virtualMachines'].id" -o tsv) $1>/dev/null


echo ""
echo "To delete the created resource groups run the following."
DELETE_CMD=''
for group in ${RESOURCE_GROUPS[@]}; do
    if [[ ${DELETE_CMD} ]]; then
        DELETE_CMD="${DELETE_CMD} && az group delete -n ${group} --no-wait --yes"
    else
        DELETE_CMD="az group delete -n ${group} --no-wait --yes"
    fi
done

echo "'${DELETE_CMD}'"
