@Library('slack') _

pipeline {
    agent any

    environment {
        deploymentName = "devsecops"
        containerName = "devsecops-container"
        serviceName = "devsecops-svc"
        imageName = "mojibakara/numeric-app:${GIT_COMMIT}"
        applicationURL="http://167.235.65.82"
        applicationURI="/compare/99"
    }
    stages {
        stage('Build Artifacts') {
            steps {
                sh 'mvn clean package -DskipTests=true'
                archive 'target/*.jar'
            }
        }
        stage('Unit Test') {
            steps {
                sh 'mvn test'
            }
            post {
              always {
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
                }
            }
        }
        stage ('Mutation Test - PIT') {
            steps {
                sh 'mvn org.pitest:pitest-maven:mutationCoverage'
            }
            post {
                always {
                    pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
                }
            }
        }
        stage ('SonarQube - SAST') {
            steps {
                withSonarQubeEnv('SonarQube') {
                  sh "mvn clean verify sonar:sonar -Dsonar.projectKey=numeric-app -Dsonar.host.url=http://167.235.65.82:9000 -Dsonar.login=sqp_2df78892d01c1917d3ae71dfaf3370c60085568b"
            }
            timeout(time: 4 , unit: 'MINUTES') {
                script {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        }
       // stage('Vulnerability Scan -Docker') {
         //   steps {
           //     sh 'mvn dependency-check:check'
            //}
            //post {
              //  always {
               //     dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                //}
           // }
       // }
           stage('Vulnerability Scan -Docker') {
            steps {
                parallel(
                    "Dependency Scan" :{
                        sh 'mvn dependency-check:check'
                    },
                    "Trivy Scan" :{
                        sh "bash trivy-docker-image-scan.sh"
                    },
                    "OPA Conftest" :{
                
                         sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
                    }
                ) 
            }
            post {
                always {
                    dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                }
            }
        }
        stage ('Docker Build and Push') {
          steps {
             withDockerRegistry([credentialsId: "docker_hub", url:""]) {
                 sh 'printenv'
                 sh 'sudo docker build -t mojibakara/numeric-app:""$GIT_COMMIT"" .'
                 sh 'docker push mojibakara/numeric-app:""$GIT_COMMIT""'
             }
          }
        }
        stage ('Vulnerability Scan - Kubernetes') {
            steps {
                parallel(
                  "OPA Scan": {
                    sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
                  },
                  "Kubesec Scan": {
                    sh "bash kubesec-scan.sh"
                  },
                  "Trivy Scan": {
                    sh "bash trivy-k8s-scan.sh"
                  }
                )
            }
        }
//        stage ('kubernetes Deployment - DEV') {
//                  steps {
//                      withKubeConfig([credentialsId: 'kubeconfig']) {
//                     sh "sed -i 's#replace#mojibakara/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
//                      sh "kubectl apply -f k8s_deployment_service.yaml"  
//                      }
//                  }
//        }
                stage ('kubernetes Deployment - DEV') {
                  steps {
                    parallel(
                     "Deployment" :{
                        withKubeConfig([credentialsId: 'kubeconfig']) {
                            sh "bash k8s-deployment.sh"
                        }
                    },
                    "RollOut Status" :{
                      withKubeConfig([credentialsId: 'kubeconfig']) {
                        sh "bash k8s-deployment-rollout-status.sh"
                        } 
                    }
                    )
                }
              }
              stage("Integeration Tests - Dev") {
                steps {
                    script {
                        try {
                            withKubeConfig([credentialsId: 'kubeconfig']) {
                                sh "bash integeration-test.sh"
                            }
                        } catch (e) {
                            withKubeConfig([credentialsId: 'kubeconfig']) {
                                sh "kubectl -n default rollout undo deploy ${deploymentName}"
                            }
                            throw e
                        }

                        }
                    }
           }
             stage('OWASP ZAP - DAST') {
               steps {
                 withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh 'bash zap.sh'
                }
            }
              post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap-report.html', reportName: 'HTML Report', reportTitles: 'OWAP ZAP Report HTML', useWrapperFileDirectly: true])
                    sendNotification currentBuild.result
                }
            }
       }     
       stage('Promحte to PROD?') {
        steps {
            timeout(time: 2,unit: 'DAYS') {
                input 'Do you want to Approve the Deployment to Production Enviroment/Namespace?'
            }
        }
       } 
    }
}
