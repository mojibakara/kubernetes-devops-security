#!/bin/bash

#k8s-deployment.sh

sed -i "s#replcae#${imageName}#g" k8s_deployment_service.yaml
sudo cp ./k8s_deployment_service.yaml k8s-devsecops-security-CD/
cd k8s-devsecops-security-CD/
git add .
git commit -m "update deploy"
git push
kubectl -n default get deployment ${deploymentName} > /dev/null
sleep 300
if [[ $? -ne 0 ]]; then
    echo "deployment ${deploymentName} doesnt exist"
   # kubectl -n default apply -f k8s_deployment_service.yaml
else
    echo "deployment ${deploymentName} exist"
    echo "image name - ${imageName}"
    kubectl -n default set image deploy ${deploymentName} ${containerName}=${imageName} --record=true
fi;