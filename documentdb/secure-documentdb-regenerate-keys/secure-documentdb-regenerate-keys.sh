#!/bin/bash

# Regenerate account keys
az documentdb regenerate-key \
    --name docdb-test \
    --resource-group myResourceGroup \
	--key-kind secondary
