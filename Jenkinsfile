@Library('slack') _

pipeline {
    agent any

    environment {
        deploymentName = "devsecops"
        containerName = "devsecops-container"
        serviceName = "devsecops-svc"
        imageName = "mojibakara/numeric-app::${GIT_COMMIT}"
        applicationURL="http://94.130.228.70"
        applicationURI="/compare/99"
    }
    stages {
        stage('Build Artifacts') {
            // agent {
            //     label "WNK-02"
            // }
            // test
            steps {
                sh 'mvn clean package -DskipTests=true'
                archive 'target/*.jar'
            }
         }
        stage('Unit Test') {
            // agent {
            //     label "WNK-02"
            // }
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
            // agent {
            //     label "WNK-02"
            // }
            steps {
                withSonarQubeEnv('SonarQube') {
                  sh "mvn clean verify sonar:sonar -Dsonar.projectKey=SAST_TEST -Dsonar.host.url=http://94.130.228.70:9000 -Dsonar.login=sqp_1075908212f147df6badb23d4f9fb6be9783435e"
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
                label "MNF-01"
              }
            steps {
                parallel(
                    "Dependency Scan" :{
                        sh 'mvn dependency-check:check'
                        // sh 'echo ok'
                    },
                    "Trivy Scan" :{
                        sh "bash trivy-docker-image-scan.sh"
                    },
                    "OPA Conftest" :{
                
                         sh 'sudo docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
                    }
                ) 
                    // sh 'echo Done'
            }
            post {
                always {
                    dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                }
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
                    sh 'sudo docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
                  },
                //   "Kubesec Scan": {
                //     sh "bash kubesec-scan.sh"
                //   },
                  "Trivy Scan": {
                    sh "bash trivy-k8s-scan.sh"
                  }
                )
            }
        }
                stage ('Argocd_Check') {
                  steps {
                    sh "bash argocd-status.sh"   
                    // sh 'echo Done'    
                  }
                }
            //     stage ('kubernetes Deployment - DEV') {
            //       steps {
            //         parallel(
            //          "Deployment" :{
            //             withKubeConfig([credentialsId: 'kubeconfig']) {
            //                 sh "bash k8s-deployment.sh"
            //             }
            //         },
            //         "RollOut Status" :{
            //           withKubeConfig([credentialsId: 'kubeconfig']) {
            //             sh "bash k8s-deployment-rollout-status.sh"
            //             } 
            //             }
            //         )
            //     }
            //   }

        //       stage("Integeration Tests - Dev") {
        //         steps {
        //             script {
        //                 try {
        //                     withKubeConfig([credentialsId: 'kubeconfig']) {
        //                         sh "bash integeration-test.sh"
        //                     }
        //                 } catch (e) {
        //                     withKubeConfig([credentialsId: 'kubeconfig']) {
        //                         sh "kubectl -n default rollout undo deploy ${deploymentName}"
        //                     }
        //                     throw e
        //                 }

        //                 }
        //             }
        //    }
             stage('OWASP ZAP - DAST') {
                agent {
                label "MNF-01"
              }
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
       stage('K8S CIS Benchmark') {
        steps {
            script {
                parallel(
                    "Master": {
                        sh "bash cis-master.sh"
                    },
                    // "Etcd": {
                    //     sh "bash cis-etcd.sh"
                    // },
                    "Kubelet": {
                        sh "bash cis-kubelet.sh"
                    }
                )
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
                // pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
                // dependencyCheckPublisher pattern: '**/target/dependency-check-report.xml'
                publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap-report.html', reportName: 'HTML Report', reportTitles: 'OWAP ZAP Report HTML', useWrapperFileDirectly: true])
                }
            }
    }