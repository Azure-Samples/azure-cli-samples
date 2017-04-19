#!/bin/bash

# Create a firewall
az documentdb update \
	--name docdb-test \
	--resource-group myResourceGroup \
	--ip-range-filter "13.91.6.132,13.91.6.1/24" 
	

