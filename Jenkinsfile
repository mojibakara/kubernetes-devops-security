pipeline {
    agent any

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
                 sh 'docker build -t mojibakara/numeric-app:""$GIT_COMMIT"" .'
                 sh 'docker push mojibakara/numeric-app:""$GIT_COMMIT""'
             }
          }
        }
        stage ('kubernetes Deployment - DEV') {
                  steps {
                      withKubeConfig([credentialsId: 'kubeconfig']) {
                      sh "sed -i 's#replace#mojibakara/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                      sh "kubectl apply -f k8s_deployment_service.yaml"  
                      }
                  }
        }
    }
}
