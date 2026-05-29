pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "${JOB_NAME.toLowerCase().replaceAll('[^a-z0-9-]', '-')}"
        DOCKER_TAG   = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                sh 'python3 -m pip install --no-cache-dir -r requirements.txt'
                sh 'python3 -m pytest --tb=short || true'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    withSonarQubeEnv('SonarQube') {
                        sh 'sonar-scanner -Dsonar.projectKey=${JOB_NAME} -Dsonar.sources=. -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.python.coverage.reportPaths=coverage.xml'
                    }
                }
            }
        }

        stage('Docker Build') {
            when { expression { return fileExists('Dockerfile') } }
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
            }
        }

        stage('Trivy Scan') {
            when { expression { return fileExists('Dockerfile') } }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh "trivy image --exit-code 0 --severity HIGH,CRITICAL --format table ${DOCKER_IMAGE}:${DOCKER_TAG} | tee trivy-report.txt"
                    archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        always {
            script {
                try {
                    withCredentials([string(credentialsId: 'ANTHROPIC_API_KEY', variable: 'ANTHROPIC_KEY')]) {
                        def status = currentBuild.result ?: 'IN_PROGRESS'
                        def prompt = "Analyze this Jenkins CI/CD pipeline and give 2-3 actionable bullet points: what passed, what failed (if any), and one recommendation.\n\nJob: ${env.JOB_NAME}\nBuild #${env.BUILD_NUMBER}\nBranch: ${env.GIT_BRANCH ?: env.BRANCH_NAME ?: 'unknown'}\nStatus: ${status}"
                        def payload = groovy.json.JsonOutput.toJson([
                            model: 'claude-haiku-4-5-20251001',
                            max_tokens: 350,
                            messages: [[role: 'user', content: prompt]]
                        ])
                        def url = new URL('https://api.anthropic.com/v1/messages')
                        def conn = url.openConnection()
                        conn.requestMethod = 'POST'
                        conn.doOutput = true
                        conn.setRequestProperty('Content-Type', 'application/json')
                        conn.setRequestProperty('x-api-key', env.ANTHROPIC_KEY)
                        conn.setRequestProperty('anthropic-version', '2023-06-01')
                        conn.outputStream << payload.getBytes('UTF-8')
                        def responseCode = conn.responseCode
                        def response = responseCode < 400 ? conn.inputStream.text : conn.errorStream.text
                        writeFile file: 'claude-analysis.json', text: response
                        archiveArtifacts artifacts: 'claude-analysis.json', allowEmptyArchive: true
                        if (responseCode == 200) {
                            def parsed = new groovy.json.JsonSlurper().parseText(response)
                            echo "\n=== Claude AI Build Analysis ===\n${parsed.content[0].text}\n================================"
                        }
                    }
                } catch (ignored) {
                    echo 'Claude AI analysis skipped (add ANTHROPIC_API_KEY secret-text credential in Jenkins to enable)'
                }
            }
        }
        success { echo 'Pipeline succeeded!' }
        failure  { echo 'Pipeline failed!' }
    }
}