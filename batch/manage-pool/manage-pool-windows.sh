#!/bin/bash

# Authenticate Batch account CLI session.
az batch account login -g myresource group -n mybatchaccount

# We want to add an application package reference to the pool, so first
# we'll list the available applications.
az batch application summary list

# Create a new Windows cloud service platform pool with 3 Standard A1 VMs.
# The pool has an application package reference (taken from the output of the
# above command) and a start task that will copy the application files to a shared directory.
az batch pool create \
    --id mypool-windows \
    --os-family 4 \
    --target-dedicated 3 \
    --vm-size small \
    --start-task-command-line "cmd /c xcopy %AZ_BATCH_APP_PACKAGE_MYAPP% %AZ_BATCH_NODE_SHARED_DIR%" \
    --start-task-wait-for-success \
    --application-package-references myapp

# We can add some metadata to the pool.
az batch pool set --pool-id mypool-windows --metadata IsWindows=true VMSize=StandardA1

# Let's change the pool to enable automatic scaling of compute nodes.
# This autoscale formula specifies that the number of nodes should be adjusted according
# to the number of active tasks, up to a maximum of 10 compute nodes.
az batch pool autoscale enable \
    --pool-id mypool-windows \
    --auto-scale-formula "$averageActiveTaskCount = avg($ActiveTasks.GetSample(TimeInterval_Minute * 15));$TargetDedicated = min(10, $averageActiveTaskCount);"

# We can monitor the resizing of the pool.
az batch pool show --pool-id mypool-windows

# Once we no longer require the pool to automatically scale, we can disable it.
az batch pool autoscale disable --pool-id mypool-windows