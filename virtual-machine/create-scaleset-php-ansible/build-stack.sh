#!/usr/bin/env bash
set -e
# Any subsequent commands which fail will cause the shell script to exit immediately

RESOURCE_GROUP='php-stack'
LOCATION='westus'
SCALE_SET_NAME='phpScaleSet'
RANDOM_NUM=$(python -S -c "import random; print(random.randrange(1000,63000))")

# Read in the public key
if [ -r ~/.ssh/id_rsa.pub ]; then
    SSH_PUB_KEY=$(cat ~/.ssh/id_rsa.pub)
else
    read -e -p "I couldn't find ~/.ssh/id_rsa.pub. Please provide a path to your public key: " FILE_PATH
    eval FILE_PATH=${FILE_PATH}
    while [ ! -e ${FILE_PATH} ]; do
        read -e -p "I couldn't find $FILE_PATH. Please provide a path to your public key: " FILE_PATH
    done
    SSH_PUB_KEY=`cat ${FILE_PATH}`
fi


# Create the resource group if it doesn't exist
echo "Creating resource group ${RESOURCE_GROUP} in ${LOCATION}"
az group create -n ${RESOURCE_GROUP} -l ${LOCATION} 1>/dev/null


# Build the Scale Set
VMSS_NAME=$(az vmss list -g ${RESOURCE_GROUP} --query "[?name=='${SCALE_SET_NAME}'].name | [0]" -o tsv)
if [ -z ${VMSS_NAME} ]; then
    echo "Creating a virtual machine scale set with a randomized DNS name"
    az vmss create -n ${SCALE_SET_NAME} -g ${RESOURCE_GROUP} --public-ip-address-dns-name "lamp-sample-$RANDOM_NUM" \
        --image CentOS --storage-sku Premium_LRS --authentication-type ssh --ssh-key-value "${SSH_PUB_KEY}" \
        --admin-username deploy --vm-sku Standard_DS3_v2 1>/dev/null
else
    echo "Virtual machine scale set has already been created"
fi


# Add a load balanced endpoint on port 80 routed to the backend servers on port 80
HTTP_RULE_NAME=$(az network lb rule list -g ${RESOURCE_GROUP} --lb-name ${SCALE_SET_NAME}LB \
    --query "[?name=='http-rule'].name | [0]" -o tsv)
if [ -z ${HTTP_RULE_NAME} ]; then
    echo "Creating a load balanced endpoint on port 80 routed to the backend servers on port 80"
    az network lb rule create -g ${RESOURCE_GROUP} -n http-rule --backend-pool-name ${SCALE_SET_NAME}LBBEPool \
        --backend-port 80 --frontend-ip-name LoadBalancerFrontEnd --frontend-port 80 --lb-name ${SCALE_SET_NAME}LB \
        --protocol Tcp 1>/dev/null
else
    echo "Load balanced endpoint on port 80 has already been created"
fi


FQDN=$(az network public-ip list -g ${RESOURCE_GROUP} --query \
                "[?starts_with(dnsSettings.fqdn, 'lamp-sample-')].dnsSettings.fqdn | [0]" -o tsv)

echo ""
echo "Two virutal machine instances within the scale set have been created with a network load balancer."
echo "NAT rules have been setup to route SSH traffic to the scale set instances."
echo "To SSH to the machines run the following: "
PORTS=$(az network lb show -g ${RESOURCE_GROUP} -n ${SCALE_SET_NAME}LB \
    --query "inboundNatRules[].{backend: backendPort, frontendPort: frontendPort}" -o tsv)
while read CMD; do
    read _ frontend <<< "${CMD}"
    echo "'ssh deploy@${FQDN} -p ${frontend}'"
done <<< "${PORTS}"

echo ""
echo "You can now reach the scale set by opening your browser to: 'http://${FQDN}'."


echo ""
echo "Creating a virtual machine scale set custom script extension which will provide configuration"
echo "to each of the virtual machines within the scale set on how to provision their software stack."
echo "This configuration contains commands to be executed upon provisioning of instances. This is helpful for"
echo "hooking into configuration management software or simply provisioning your software stack directly."
# apply a custom script extension to setup baseline provisioning for the ScaleSet
az vmss extension set -n CustomScript --publisher Microsoft.Azure.Extensions --version 2.0 \
   -g ${RESOURCE_GROUP} --vmss-name ${SCALE_SET_NAME} --protected-settings ./protected_config.json 1>/dev/null

echo ""
echo "Now that the custom script extension has been created, this command will cause each instance of the"
echo "scale set to run the latest version of the script extension."
az vmss update-instances --instance-ids "*" -n ${SCALE_SET_NAME} -g ${RESOURCE_GROUP} 1>/dev/null


echo ""
echo "Scaling up to 5 instances."
az vmss scale --new-capacity 5 -n ${SCALE_SET_NAME} -g ${RESOURCE_GROUP} 1>/dev/null

echo ""
echo "Five virtual machine instances within the scale set have been created with a network load balancer."
echo "NAT rules have been setup to route SSH traffic to the scale set instances."
echo "To SSH to the machines run the following: "
PORTS=$(az network lb show -g ${RESOURCE_GROUP} -n ${SCALE_SET_NAME}LB \
    --query "inboundNatRules[].{backend: backendPort, frontendPort: frontendPort}" -o tsv)
while read CMD; do
    read _ frontend <<< "${CMD}"
    echo "'ssh deploy@${FQDN} -p ${frontend}'"
done <<< "${PORTS}"

echo ""
echo "You can reach the scale set by opening your browser to: 'http://${FQDN}'."

echo ""
echo "You can delete the stack by running: 'az group delete -n ${RESOURCE_GROUP}'."






