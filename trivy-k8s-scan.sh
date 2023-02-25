#!/bin/bash
#trivy-k8s-scan

echo $imageName #getting Imgae name env variable

docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.17.2 -q image --exit-code 0 --sevirity LOW,MEDIUM,HIGH --light $imageName
docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.17.2 -q image --exit-code 1 --sevirity CRITICAL --light $imageName

    # Trivy Scan result proccesing
    exit_code=$?
    echo "Exit_Code : $exit_code"

    #Check scan results
    if [[ $(exit_code) == 1 ]]; then
        echo "Image scanning failed. Vulnerability Found"
        exit 1;
    else
        echo "Image scanning passed. No Vulnerability Found"
    fi;