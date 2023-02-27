#!/bin/bash

PORT=$(kubectl -n default get svc ${serviceName} -o json | jq .spec.ports[].nodePort)

# first run this
chmode 777 $(pwd)
echo $(pwd)
echo $(id -u):$(id -g)
sudo docker run -v $(pwd):/zap/wrk/:rw -t owasp/zap2docker-weekly zap-api-scan.py -t $applicationURL:$PORT/v3/api-docs -f openapi -r zap_report.html
#docker run -v $(pwd):/zap/wrk/:rw -t owasp/zap2docker-weekly zap-api-scan.py -t $applicationURL:$PORT/v3/api-docs -f openapi -c zap-rules -w report



# HTML report
 sudo mkdir -p owasp-zap-report
 sudo mv zap_report.html owasp-zap-report

exit_code=$?
echo "Exit Code : $exit_code"

 if [[ ${exit_code} -ne 0 ]]; then
    echo "OWASP ZAP Report has either low/Medium/High Risk. Please chek the HTML Report"
    exit 1;
   else
    echo "OWASP ZAP did not report any risk"
  fi;
