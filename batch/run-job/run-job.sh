#!/bin/bash

# Authenticate Batch account CLI session.
az batch account login -g myresource group -n mybatchaccount

# Create a new job to encapsulate the tasks that we want to add.
# We'll assume a pool has already been created with the ID 'mypool' - for more information
# see the sample script for managing pools.
az batch job create --id myjob --pool-id mypool

# Now we will add tasks to the job.
# We'll assume an application package has already been uploaded with the ID 'myapp' - for
# more information see the sample script for adding applications.
az batch task create \
    --job-id myjob \
    --id task1 \
    --application-package-references myapp#1.0
    --command-line "cmd /c %AZ_BATCH_APP_PACKAGE_MYAPP#1.0%\\myapp.exe"

# If we want to add many tasks at once - this can be done by specifying the tasks
# in a JSON file, and passing it into the command. See tasks.json for formatting.
az batch task create --job-id myjob --json-file tasks.json

# Now that all the tasks are added - we can update the job so that it will automatically
# be marked as completed once all the tasks are finished.
az batch job set --on-all-tasks-complete terminateJob

# Monitor the status of the job.
az batch job show --job-id myjob

# Monitor the status of a task.
az batch task show --task-id task1
