#!/bin/bash

FQDN=$(az network public-ip list -g myResourceGroup --query \
                "[?starts_with(dnsSettings.fqdn, 'my-lamp-')].dnsSettings.fqdn | [0]" -o tsv)

PORTS=$(az network lb show -g myResourceGroup -n myScaleSetLB \
    --query "inboundNatRules[].{backend: backendPort, frontendPort: frontendPort}" -o tsv)
while read CMD; do
    read _ frontend <<< "${CMD}"
    echo "'ssh deploy@${FQDN} -p ${frontend}'"
done <<< "${PORTS}"

echo ""
echo "You can now reach the scale set by opening your browser to: 'http://${FQDN}'."