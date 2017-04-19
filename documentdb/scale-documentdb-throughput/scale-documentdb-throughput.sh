#!/bin/bash

# Scale throughput
az documentdb update \
	--name docdb-test \
    --resource-group myResourceGroup \
    --collname mysamplecollection \
	--throughput 10000


*Need CLI commands for collname and throughput
