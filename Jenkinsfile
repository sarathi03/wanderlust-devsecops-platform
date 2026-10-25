pipeline {
    agent {
        label 'wanderlust-agent'
    }

    environment {
        SONAR_HOME = tool 'Sonar'
    }

    parameters {
        string(
            name: 'FRONTEND_DOCKER_TAG',
            defaultValue: '',
            description: 'Docker image tag for the frontend'
        )
        string(
            name: 'BACKEND_DOCKER_TAG',
            defaultValue: '',
            description: 'Docker image tag for the backend'
        )
    }

    stages {

        stage('Validate Parameters') {
            steps {
                script {
                    if (!params.FRONTEND_DOCKER_TAG?.trim() ||
                        !params.BACKEND_DOCKER_TAG?.trim()) {
                        error('Please provide both FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG.')
                    }
                }
            }
        }

        stage('Workspace Cleanup') {
            steps {
                cleanWs()
            }
        }

        stage('Git: Code Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/sarathi03/wanderlust-devsecops-platform.git'
            }
        }

        stage('Trivy: Filesystem Scan') {
            steps {
                sh '''
                    trivy fs \
                        --scanners vuln,misconfig \
                        --format json \
                        --output trivy-report.json \
                        .
                '''
            }
        }

        stage('OWASP: Dependency Check') {
            steps {
                dependencyCheck(
                    additionalArguments: '--scan . --format XML --format HTML',
                    odcInstallation: 'DP-Check'
                )

                dependencyCheckPublisher(
                    pattern: '**/dependency-check-report.xml'
                )
            }
        }

        stage('SonarQube: Code Analysis') {
            steps {
                withSonarQubeEnv('Sonar') {
                    sh '''
                        "$SONAR_HOME/bin/sonar-scanner" \
                            -Dsonar.projectKey=wanderlust \
                            -Dsonar.projectName=wanderlust \
                            -Dsonar.sources=.
                    '''
                }
            }
        }

        stage('SonarQube: Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Exporting Environment Variables') {
            parallel {

                stage('Backend Environment Setup') {
                    steps {
                        dir('Automations') {
                            sh 'bash updatebackendnew.sh'
                        }
                    }
                }

                stage('Frontend Environment Setup') {
                    steps {
                        dir('Automations') {
                            sh 'bash updatefrontendnew.sh'
                        }
                    }
                }
            }
        }

        stage('Docker: Build Images') {
            steps {
                dir('backend') {
                    sh '''
                        docker build \
                            -t sarathimohan/wanderlust-backend-beta:${BACKEND_DOCKER_TAG} \
                            .
                    '''
                }

                dir('frontend') {
                    sh '''
                        docker build \
                            -t sarathimohan/wanderlust-frontend-beta:${FRONTEND_DOCKER_TAG} \
                            .
                    '''
                }
            }
        }

        stage('Docker: Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x

                        echo "$DOCKERHUB_TOKEN" | docker login \
                            --username "$DOCKERHUB_USER" \
                            --password-stdin

                        docker push \
                            sarathimohan/wanderlust-backend-beta:${BACKEND_DOCKER_TAG}

                        docker push \
                            sarathimohan/wanderlust-frontend-beta:${FRONTEND_DOCKER_TAG}

                        docker logout
                    '''
                }
            }
        }
    }

/*
AWS ENVIRONMENT SETUP — DISABLED FOR NOW

stage('Exporting Environment Variables') {
    parallel {
        stage('Backend Environment Setup') {
            steps {
                script {
                    dir('Automations') {
                        sh 'bash updatebackendnew.sh'
                    }
                }
            }
        }

        stage('Frontend Environment Setup') {
            steps {
                script {
                    dir('Automations') {
                        sh 'bash updatefrontendnew.sh'
                    }
                }
            }
        }
    }
}
*/
    post {
        always {
            archiveArtifacts(
                artifacts: 'trivy-report.json, **/dependency-check-report.xml, **/dependency-check-report.html',
                allowEmptyArchive: true
            )
        }
    }
}