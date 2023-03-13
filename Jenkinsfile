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
        }
        stage ('Mutation Test - PIT') {
            steps {
                sh 'mvn org.pitest:pitest-maven:mutationCoverage'
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
            // sh 'bash checkmarx.sh'
        }
        }
     
           stage('Vulnerability Scan -Docker') {
                agent {
                        label "WNK-02"
                    }
            steps {
                parallel(
                    "Dependency Scan" :{
                        sh 'mvn dependency-check:check'
                    },
                    "Trivy Scan" :{
                        sh "bash trivy-docker-image-scan.sh"
                    },
                    "OPA Conftest" :{
                
                         sh 'sudo docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
                    }
                ) 
            }
        }
        stage('Increment Build Version') {
            steps {
                script {
                    echo 'incrementing app version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                    def version = matcher[0][1]
                    env.IMAGE_NAME = "$version-$BUILD_NUMBER"
                }
            }
        }
        stage ('Docker Build and Push') {
          steps {
             withDockerRegistry([credentialsId: "docker_hub", url:""]) {
                 sh 'printenv'
                //  sh 'sudo docker build -t mojibakara/numeric-app:""$GIT_COMMIT"" .'
                //  sh 'docker push mojibakara/numeric-app:""$GIT_COMMIT""'
                 sh 'sudo docker build -t mojibakara/numeric-app:${IMAGE_NAME} .'
                 sh 'docker push mojibakara/numeric-app:${IMAGE_NAME}'
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
                stage ('Argocd_Check') {
                  steps {
                    sh "bash argocd-status.sh"       
                  }
                }
                // stage ('kubernetes Deployment - DEV') {
                //   steps {
                //     parallel(
                //      "Deployment" :{
                //         withKubeConfig([credentialsId: 'kubeconfig']) {
                //             sh "bash k8s-deployment.sh"
                //         }
                //     },
                    // "RollOut Status" :{
                    //   withKubeConfig([credentialsId: 'kubeconfig']) {
                    //     sh "bash k8s-deployment-rollout-status.sh"
                    //     } 
              //       // }
              //       )
              //   }
              // }

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
       }     
       stage('Prompte to PROD?') {
        steps {
            timeout(time: 2,unit: 'DAYS') {
                input 'Do you want to Approve the Deployment to Production Enviroment/Namespace?'
            }
        }
       }
    // stage('test') {
    //   steps {
    //         sh 'exit 0'
    //     }
    // }
    }
       post {
             always {
                sendNotification currentBuild.result
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
                pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
                dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap-report.html', reportName: 'HTML Report', reportTitles: 'OWAP ZAP Report HTML', useWrapperFileDirectly: true])
                }
            }
    }