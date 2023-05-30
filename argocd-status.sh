#!/bin/bash

#argocd_status.sh
sleep 300
output_token=$(curl -k https://94.130.228.70:32392/api/v1/session -d $'{"username":"admin","password":"Yef7-0b5xB0STcI6"}' | cut -d '"' -f4)

app_sync=$(curl -k https://94.130.228.70:32392/api/v1/applications/myapp/sync -d $'{"username":"admin","password":"Yef7-0b5xB0STcI6"}')

sleep 120s
sync_status=$(curl -k https://94.130.228.70:32392/api/v1/applications -H "Authorization: Bearer $output_token" | jq '.["items"][0]["status"]["operationState"]["message"]' | sed 's/"//' | sed 's/"//')
health_status=$(curl -k https://94.130.228.70:32392/api/v1/applications -H "Authorization: Bearer $output_token" | jq '.["items"][0]["status"]["resources"][0]["health"]["status"]' | sed 's/"//' | sed 's/"//')

echo Hello
echo $output_token
echo $sync_status
echo $health_status

if [[ "$sync_status" == "successfully synced (all tasks run)" && "$health_status" == "Healthy" ]]; then
    echo "Deployment has been Successsed"
    exit 0;
else
    echo "Deployment has been Unsuccessed"
    exit 1;
fi;
