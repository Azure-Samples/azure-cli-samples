#!/bin/bash

# Get the connection string for MongoDB apps
az documentdb list-connection-strings \
    --name docdb-test \
    --resource-group myResourceGroup 
