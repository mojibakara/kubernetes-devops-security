#!/bin/bash

#argocd_status.sh

output_token=$(curl -k https://167.235.65.82:32263/api/v1/session -d $'{"username":"admin","password":"QYXdF2KS15gZFIJh"}' | cut -d '"' -f4)

sync_status=$(curl -k https://167.235.65.82:32263/api/v1/applications -H "Authorization: Bearer $output_token" | jq '.["items"][0]["status"]["operationState"]["message"]')
health_status=$(curl -k https://167.235.65.82:32263/api/v1/applications -H "Authorization: Bearer $output_token" | jq '.["items"][0]["status"]["resources"][0]["health"]["status"]')


if [[ "${sync_status}" -eq "successfully synced (all tasks run)" && "${health_status}" -eq "Healthy" ]]; then
    echo "Successs"
    exit 0;
else
    echo "Unsuccess"
    exit 1;
fi;
