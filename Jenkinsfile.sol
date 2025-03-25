pipeline {
    agent any

    environment {
        IMAGE_NAME = "alianib/my-python-application"
        DOCKER_LOGIN = "alianib" // Initialisation de la variable
    }

    stages {
        stage('Init') {
            steps {
                script {
                    env.BUILD_VERSION = "1.0.${BUILD_NUMBER}" // Définition dynamique
                }
            }
        }

    //    stage('Checkout Code') {
     //       steps {
       //         git 'https://github.com/BAliani/my-python-project.git'  // Remplace par ton repo
         //   }
        //}

        stage('Static Code Analysis (Flake8)') {
            parallel {
                stage('Flake8 Linting') {
                    steps {
                        script {
                            try {
                                sh 'python3 --version'
                                sh 'python3 -m flake8 --version'
                                sh 'python3 -m flake8 . --count --show-source --statistics || true'
                            } catch (Exception e) {
                                echo "Flake8 a retourné des erreurs mais n'a pas bloqué le pipeline."
                            }
                        }
                    }
                }

                stage('Unit Tests (Pytest)') {
                    steps {
                        script {
                            try {
                                //sh 'pip install -r requirements.txt'
                                //sh 'pip install pytest'
                                sh 'pytest | tee report.txt'
                            } catch (Exception e) {
                                echo "Les tests unitaires ont échoué!"
                                currentBuild.result = 'UNSTABLE'  // Marque le build comme instable si les tests échouent
                            }
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'report.txt', fingerprint: true
                        }
                    }
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'DOCKER_PASSWORD', variable: 'DOCKER_PASS')]) {
                        sh """
                            docker build -t ${IMAGE_NAME}:${env.BUILD_VERSION} .
                            docker login -u $DOCKER_LOGIN -p $DOCKER_PASS
                            docker push ${IMAGE_NAME}:${env.BUILD_VERSION}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline exécuté avec succès !"
        }
        failure {
            echo "Le pipeline a échoué. Vérifiez les logs."
        }
    }
}
