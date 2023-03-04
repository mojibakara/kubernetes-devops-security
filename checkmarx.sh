#! /bin/bash

dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)
echo $dockerImageName

#docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.17.2 -q image --exit-code 1 --severity CRITICAL --light $dockerImageName
docker run -it -u $UID:$GID -v $PWD/path checkmarx/kics:ubi8 scan -p $PWD -o /path -v

#Trivy scan result proccesing
exit_code=$?
echo "Exit Code : $exit_code"

# check scan result
if [[ "${exit_code}" == 1 ]] ; then
    echo "Image scanning failed. Vulnerabilities found"
    exit 1;
else
    echo "Image scanning passed. No Vulnerabilities found"
fi;
