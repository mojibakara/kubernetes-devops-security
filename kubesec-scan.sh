#!/bin/bash

#kubesec-scan.sh
#using kubesec v2 api
scan_result=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan)
scan_message=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan | jq .[0].message -r )
scan_score=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan | jq .[0].score )

#using kubesec docker image for scanning
# scan_result=$(docker run -i kubesec/kubesec:5125c5e0 scan /dev/stdin < k8s_deployment_service.yaml)
# scan_message=$(docker run -i kubesec/kubesec:5125c5e0 scan /dev/stdin < k8s_deployment_service.yaml | jq .[].message -r)
# scan_score=$(docker run -i kubesec/kubesec:5125c5e0 scan /dev/stdin < k8s_deployment_service.yaml | jq .[].socre)

    # kubesec scan result proccessing
    echo "Scan Score : $scan_socre"

    if [[ "${scan_score}" -ge 3 ]]; then
        echo "Score is $scan_score"
        echo "Kubesec Scan $scan_message"
    else
        echo "Score is $scan_score, which is less than or equal to 3."
        echo "Scanning Kubernetes Resource has failed"
        exit 1;
    fi;