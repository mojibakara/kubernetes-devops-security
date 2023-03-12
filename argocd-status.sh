#!/bin/bash

#argocd_status.sh

output_token=$(curl -k https://167.235.65.82:32263/api/v1/session -d $'{"username":"admin","password":"QYXdF2KS15gZFIJh"}' | cut -d '"' -f4)

sync_status=$(curl -k https://167.235.65.82:32263/api/v1/applications -H "Authorization: Bearer $output_token" | jq '.["items"][0]["status"]["operationState"]["message"]' | sed 's/"//' | sed 's/"//')
health_status=$(curl -k https://167.235.65.82:32263/api/v1/applications -H "Authorization: Bearer $output_token" | jq '.["items"][0]["status"]["resources"][0]["health"]["status"]' | sed 's/"//' | sed 's/"//')

echo $output_token
echo $sync_status
echo $health_status

if [[ "$sync_status" == "successfully synced (all tasks run)" && "$health_status" == "Healthy" ]]; then
    echo "Successs"
    exit 0;
else
    echo "Unsuccess"
    exit 1;
fi;
