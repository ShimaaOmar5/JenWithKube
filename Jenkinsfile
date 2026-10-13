pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_NAME = 'kapp'
        REPO_URL = 'https://github.com/ShimaaOmar5/JenWithKube.git'
        GIT_BRANCH = 'main'
        K8S_DIR = 'K8s'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${GIT_BRANCH}",
                    credentialsId: 'jenkins',
                    url: "${REPO_URL}"

                sh '''
                    set -eu
                    echo "=== Repository files ==="
                    ls -la
                    echo "=== Kubernetes manifests ==="
                    ls -la "$K8S_DIR"
                '''
            }
        }

        stage('Validate Application') {
            steps {
                sh '''
                    set -eu

                    test -f kapp.py
                    test -f req.txt
                    test -f Dockerfile
                    test -f "$K8S_DIR/deployment.yaml"
                    test -f "$K8S_DIR/service.yaml"

                    grep -q 'IMAGE_PLACEHOLDER' \
                        "$K8S_DIR/deployment.yaml"

                    echo "Application files validated successfully."
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu

                    docker build \
                        -t "$APP_NAME:$BUILD_NUMBER" .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'Docker_Python_App',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -eu

                        IMAGE="$DOCKER_USERNAME/$APP_NAME:$BUILD_NUMBER"

                        echo "$DOCKER_PASSWORD" |
                            docker login \
                                --username "$DOCKER_USERNAME" \
                                --password-stdin

                        docker tag \
                            "$APP_NAME:$BUILD_NUMBER" \
                            "$IMAGE"

                        docker push "$IMAGE"

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'kubeconfig',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    ),
                    file(
                        credentialsId: 'kubeconfig',
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {
                    sh '''
                        set -eu

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        IMAGE="$DOCKER_USERNAME/$APP_NAME:$BUILD_NUMBER"

                        sed "s|IMAGE_PLACEHOLDER|$IMAGE|g" \
                            "$K8S_DIR/deployment.yaml" \
                            > deployment.rendered.yaml

                        echo "=== Kubernetes API ==="
                        kubectl get nodes

                        echo "=== Apply Deployment ==="
                        kubectl apply \
                            -f deployment.rendered.yaml

                        echo "=== Apply Service ==="
                        kubectl apply \
                            -f "$K8S_DIR/service.yaml"

                        echo "=== Verify Rollout ==="
                        kubectl rollout status \
                            deployment/python-k8s-app \
                            --timeout=180s

                        echo "=== Deployment ==="
                        kubectl get deployment python-k8s-app

                        echo "=== Pods ==="
                        kubectl get pods \
                            -l app=python-k8s-app

                        echo "=== Service ==="
                        kubectl get service \
                            python-k8s-app-service
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'CI/CD pipeline failed. Check the failed stage in the console.'
        }

        always {
            echo 'Pipeline execution finished.'
        }
    }
}