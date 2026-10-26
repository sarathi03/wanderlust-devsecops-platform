// =====================================================================================
// CI pipeline (Jenkins job: "Wanderlust-CI")
//
//   Checkout -> Unit tests -> Trivy FS scan -> OWASP Dependency-Check -> SonarQube
//   -> Quality Gate -> Docker build -> Trivy image scan -> Docker push -> trigger CD
//
// Image tag:  <BUILD_NUMBER>-<git short SHA>, e.g. 12-a1b2c3d  (same tag for both images)
// No Docker Hub username in this file: it is read from the Jenkins credential 'docker'.
// =====================================================================================
pipeline {
    agent { label 'wanderlust-agent' }

    options {
        skipDefaultCheckout(true)          // we check out explicitly in the 'Checkout' stage
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '15'))
        timeout(time: 60, unit: 'MINUTES')
    }

    environment {
        SONAR_HOME          = tool 'Sonar'          // Manage Jenkins -> Tools -> SonarQube Scanner
        BACKEND_IMAGE_NAME  = 'wanderlust-backend'
        FRONTEND_IMAGE_NAME = 'wanderlust-frontend'
        CD_JOB_NAME         = 'Wanderlust-CD'       // must match the CD job name exactly
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    // Commits made by the CD pipeline contain [skip ci]. If a GitHub webhook
                    // triggers CI for such a commit, stop here to avoid a CI -> CD -> CI loop.
                    def lastMessage = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                    if (lastMessage.contains('[skip ci]')) {
                        currentBuild.result = 'ABORTED'
                        error('Latest commit was made by the CD pipeline ([skip ci]); nothing to build.')
                    }

                    def shortSha = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${shortSha}"

                    // Image names come from the username stored in the 'docker' credential.
                    withCredentials([usernamePassword(credentialsId: 'docker',
                                                      usernameVariable: 'DOCKERHUB_USER',
                                                      passwordVariable: 'DOCKERHUB_TOKEN')]) {
                        env.BACKEND_IMAGE  = "${env.DOCKERHUB_USER}/${env.BACKEND_IMAGE_NAME}:${env.IMAGE_TAG}"
                        env.FRONTEND_IMAGE = "${env.DOCKERHUB_USER}/${env.FRONTEND_IMAGE_NAME}:${env.IMAGE_TAG}"
                    }

                    currentBuild.displayName = "#${env.BUILD_NUMBER} (${env.IMAGE_TAG})"
                    echo "Backend image : ${env.BACKEND_IMAGE}"
                    echo "Frontend image: ${env.FRONTEND_IMAGE}"
                }
            }
        }

        stage('Backend: Unit Tests') {
            steps {
                // Runs inside a throwaway node:22 container, so the agent only needs Docker.
                // -u keeps file ownership as the Jenkins user (otherwise cleanWs can fail).
                sh '''
                    docker run --rm \
                      -u "$(id -u):$(id -g)" -e HOME=/tmp \
                      -v "$WORKSPACE/backend:/app" -w /app \
                      node:22-alpine sh -c "npm ci --no-audit --no-fund && npm test"
                '''
            }
        }

        stage('Trivy: Filesystem Scan') {
            steps {
                // Report-only (--exit-code 0). Change to --exit-code 1 to fail the build on findings.
                sh '''
                    trivy fs --scanners vuln,secret,misconfig \
                      --severity HIGH,CRITICAL --exit-code 0 --no-progress \
                      --format table --output trivy-fs-report.txt .
                    cat trivy-fs-report.txt
                '''
            }
        }

        stage('OWASP: Dependency-Check') {
            steps {
                // A free NVD API key makes this stage minutes instead of hours.
                withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                    dependencyCheck(
                        odcInstallation: 'DP-Check',   // Manage Jenkins -> Tools -> Dependency-Check
                        additionalArguments: "--scan backend --format XML --format HTML --nvdApiKey ${NVD_API_KEY}"
                    )
                }
                dependencyCheckPublisher(pattern: '**/dependency-check-report.xml')
            }
        }

        stage('SonarQube: Analysis') {
            steps {
                withSonarQubeEnv('Sonar') {           // Manage Jenkins -> System -> SonarQube servers
                    sh '''
                        "$SONAR_HOME/bin/sonar-scanner" \
                          -Dsonar.projectKey=wanderlust \
                          -Dsonar.projectName=wanderlust \
                          -Dsonar.sources=backend/src,frontend \
                          -Dsonar.tests=backend/test \
                          -Dsonar.exclusions=**/node_modules/**
                    '''
                }
            }
        }

        stage('SonarQube: Quality Gate') {
            steps {
                // Waits for SonarQube to call the Jenkins webhook with the result.
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker: Build Images') {
            steps {
                // APP_VERSION is shown on the web page, so you can SEE which build is deployed.
                sh '''
                    docker build --build-arg APP_VERSION="$IMAGE_TAG" -t "$BACKEND_IMAGE"  backend
                    docker build --build-arg APP_VERSION="$IMAGE_TAG" -t "$FRONTEND_IMAGE" frontend
                '''
            }
        }

        stage('Trivy: Image Scan') {
            steps {
                sh '''
                    trivy image --severity HIGH,CRITICAL --exit-code 0 --no-progress \
                      --output trivy-image-backend.txt "$BACKEND_IMAGE"
                    trivy image --severity HIGH,CRITICAL --exit-code 0 --no-progress \
                      --output trivy-image-frontend.txt "$FRONTEND_IMAGE"
                    cat trivy-image-backend.txt trivy-image-frontend.txt
                '''
            }
        }

        stage('Docker: Push Images') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker',
                                                  usernameVariable: 'DOCKERHUB_USER',
                                                  passwordVariable: 'DOCKERHUB_TOKEN')]) {
                    sh '''
                        echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin
                        docker push "$BACKEND_IMAGE"
                        docker push "$FRONTEND_IMAGE"
                    '''
                }
            }
        }

        stage('Trigger CD') {
            steps {
                // Hands the tag to the CD job. wait:false = CI finishes now; CD runs on its own.
                build job: env.CD_JOB_NAME,
                      wait: false,
                      parameters: [string(name: 'IMAGE_TAG', value: env.IMAGE_TAG)]
                echo "Triggered ${env.CD_JOB_NAME} with IMAGE_TAG=${env.IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivy-*.txt, dependency-check-report.*', allowEmptyArchive: true
            // Free disk space on the agent; images are already on Docker Hub.
            sh '''
                docker logout >/dev/null 2>&1 || true
                [ -n "${BACKEND_IMAGE:-}" ]  && docker image rm "$BACKEND_IMAGE"  >/dev/null 2>&1 || true
                [ -n "${FRONTEND_IMAGE:-}" ] && docker image rm "$FRONTEND_IMAGE" >/dev/null 2>&1 || true
            '''
        }
        failure {
            emailext(
                to: '$DEFAULT_RECIPIENTS',   // set in Manage Jenkins -> System -> Extended E-mail Notification
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "The CI pipeline failed.\n\nBuild: ${env.BUILD_URL}\nConsole: ${env.BUILD_URL}console",
                attachLog: true
            )
        }
        cleanup {
            cleanWs()
        }
    }
}
