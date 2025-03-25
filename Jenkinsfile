pipeline {
  agent any
  
  environment {
    IMAGE_NAME = "alianib/my-python-application"
    DOCKER_LOGIN = "alianib" // Initialisation de la variable
  }
  
  stages{
    stage('Set the build number') {
      steps {
        script {
          env.BUILD_VERSION = "1.0.${BUILD_NUMBER}" 
          echo "current build version ${env.BUILD_VERSION}"
        }
      }
    }

    stage('Tests') {
      parallel {
        stage('Unit testing python code') {
          steps {
            script {
              try {
                sh 'pytest | tee report.txt'
              } catch (Exception e) {
                echo "Unit testing has failed!"
                currentBuild.result = 'UNSTABLE'
              }
            }
          }
          post {
            always {
              archiveArtifacts artifacts: 'report.txt', fingerprint: true
            }
          }
        }

        stage('Static code analysis') {
          steps {
            script {
              try {
                sh 'python3 --version'
                sh 'python3 -m flake8 --version'
                sh 'python3 -m flake8 . --count --show-source --statistics || true'
              } catch (Exception e) {
                echo "Flake8 has found errors."
              }
            }
          }
        }
      }
    }

    stage('Docker deployment') {
      steps {
        script {
          //withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_LOGIN', passwordVariable: 'DOCKER_PASS')]) {
          withCredentials([string(credentialsId: 'DOCKER_PASSWORD', variable: 'DOCKER_PASS')]) {
            sh """
              docker build -t ${IMAGE_NAME}:${env.BUILD_VERSION} .
              docker login --username $DOCKER_LOGIN --password $DOCKER_PASS
              docker push ${IMAGE_NAME}:${env.BUILD_VERSION}
            """
          }
        }
      }
    }
  }

  post {
    success {
      echo "Pipeline successfully executed !"
    }
    failure {
      echo "Pipeline failed. Verify the logs."
    }
  }
}