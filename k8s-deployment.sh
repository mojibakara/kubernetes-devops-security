#!/bin/bash

#k8s-deployment.sh

sed -i "s#replcae#${imageName}#g" k8s_deployment_service.yaml
kubectl -n default get deployment ${deploymentName} > /dev/null

if [[ $? -ne 0]]; then
    echo "deployment ${deploymentName} doesnt exist"
    kubectl -n default apply -f k8s_deployment_servie.yaml
else
    echo "deployment ${deploymentName} exist"
    echo "image name - ${imageName}"
    kubectl -n default image deploy ${deploymentName} ${cintainerName}=${imageName} --record=true
fi