pipeline {
    agent {
        label 'wanderlust-agent'
    }

    environment {
        SONAR_HOME = tool 'Sonar'
        BACKEND_IMAGE = 'sarathimohan/wanderlust-backend-beta'
        FRONTEND_IMAGE = 'sarathimohan/wanderlust-frontend-beta'
    }

    parameters {
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: 'build-1', description: 'Backend image tag')
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: 'build-1', description: 'Frontend image tag')
    }

    stages {
        stage('Validate Parameters') {
            steps {
                script {
                    if (!params.BACKEND_DOCKER_TAG?.trim() || !params.FRONTEND_DOCKER_TAG?.trim()) {
                        error('Provide both BACKEND_DOCKER_TAG and FRONTEND_DOCKER_TAG.')
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sarathi03/wanderlust-devsecops-platform.git'
            }
        }

        stage('Install and Test Backend') {
            steps {
                dir('backend') {
                    sh '''
                        npm ci
                        CI=true npm test -- --runInBand --watchAll=false
                    '''
                }
            }
        }

        stage('Install and Build Frontend') {
            steps {
                dir('frontend') {
                    sh '''
                        npm ci
                        npm run build
                    '''
                }
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    trivy fs --scanners vuln,misconfig \
                      --format json --output trivy-report.json .
                '''
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck(
                    additionalArguments: '--scan . --format XML --format HTML',
                    odcInstallation: 'DP-Check'
                )
                dependencyCheckPublisher(pattern: '**/dependency-check-report.xml')
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('Sonar') {
                    sh '''
                        "$SONAR_HOME/bin/sonar-scanner" \
                          -Dsonar.projectKey=wanderlust \
                          -Dsonar.projectName=wanderlust \
                          -Dsonar.sources=backend,frontend \
                          -Dsonar.exclusions=**/node_modules/**,**/dist/**,**/coverage/**
                    '''
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Prepare Local Environment') {
            steps {
                dir('Automations') {
                    sh 'bash updatebackendnew.sh'
                    sh 'bash updatefrontendnew.sh'
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    docker build -t "$BACKEND_IMAGE:$BACKEND_DOCKER_TAG" ./backend
                    docker build -t "$FRONTEND_IMAGE:$FRONTEND_DOCKER_TAG" ./frontend
                '''
            }
        }

        stage('Push Docker Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''
                        set +x
                        echo "$DOCKERHUB_TOKEN" | docker login \
                          --username "$DOCKERHUB_USER" --password-stdin
                        docker push "$BACKEND_IMAGE:$BACKEND_DOCKER_TAG"
                        docker push "$FRONTEND_IMAGE:$FRONTEND_DOCKER_TAG"
                        docker logout
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts(
                artifacts: 'trivy-report.json, **/dependency-check-report.xml, **/dependency-check-report.html',
                allowEmptyArchive: true
            )
        }
    }
}
