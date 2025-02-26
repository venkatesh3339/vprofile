#!/bin/bash

# Read dev.conf and create a sed command to replace placeholders in job.json
SED_COMMAND=""
while IFS='=' read -r key value; do
  # Trim leading/trailing whitespace and quotes from key and value
  key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//')
  value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//')
  
  # Append to SED_COMMAND (replace {{KEY}} with value)
  SED_COMMAND+=" -e 's/{{$key}}/$value/g'"
done < <(grep -v '^#' env/dev.conf | grep '=')

# Substitute values from dev.conf into job.json
eval "sed $SED_COMMAND job.json > final_job.json"

# Check if the job already exists
JOB_NAME=$(grep 'JOB_NAME' env/dev.conf | cut -d'=' -f2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//')
EXISTING_JOBS=$(databricks jobs list --output JSON | jq -r '.jobs[] | select(.settings.name == "'"$JOB_NAME"_dental'"") | .job_id')

# Create or update the job
if [ -z "$EXISTING_JOBS" ]; then
  echo "Creating new job: ${JOB_NAME}_dental"
  databricks jobs create --json-file final_job.json
else
  echo "Updating existing job: ${JOB_NAME}_dental (ID: $EXISTING_JOBS)"
  databricks jobs reset --job-id $EXISTING_JOBS --json-file final_job.json
fi

##################################

#!/bin/bash

# Step 1: Substitute values from dev.conf into job.json
SED_COMMAND=""
while IFS='=' read -r key value; do
  key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//')
  value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//')
  SED_COMMAND+=" -e 's/{{$key}}/$value/g'"
done < <(grep -v '^#' env/dev.conf | grep '=')

eval "sed $SED_COMMAND job.json > final_job.json"

# Step 2: Extract job name from final_job.json
JOB_NAME=$(jq -r '.name' final_job.json)

# Step 3: Check if the job already exists
EXISTING_JOBS=$(databricks jobs list --output JSON | jq -r --arg JOB_NAME "$JOB_NAME" '.jobs[] | select(.settings.name == $JOB_NAME) | .job_id')

# Step 4: Create or update the job
if [ -z "$EXISTING_JOBS" ]; then
  echo "Creating new job: $JOB_NAME"
  databricks jobs create --json-file final_job.json
else
  echo "Updating existing job: $JOB_NAME (ID: $EXISTING_JOBS)"
  databricks jobs reset --job-id $EXISTING_JOBS --json-file final_job.json
fi
