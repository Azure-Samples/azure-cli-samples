#!/bin/bash

# List account keys
az documentdb list-keys \
    --name docdb-test \
    --resource-group myResourceGroup 
