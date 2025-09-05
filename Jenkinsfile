// Basic Syntax

pipeline {
    // Pre-build section
    agent { label 'AGENT-1' }
    environment = "Jenkins-practice"

    // Build section (stages)
    stages {
        stage('Build') {
            steps {
                script {
                    sh """
                echo "Building Stage"
                env
                """
            }
            }
        }
        stage('Test') {
            steps {
                script {
                echo "Testing Stage"
            }
            }
        }
        stage('Deploy') {
            steps {
                script {
                echo "Deploying Stage"
            }
            }
        }
    }

    // Post-build section
    post { 
        always { 
            echo 'I will always say Hello again!'
            deleteDir()
        }
        changed {
            echo 'Current pipeline’s run has a different completion status from its previous run'
        }
        failure {
            echo 'Pipeline Failed'
        }
        success {
            echo 'Pipeline Success'
        }
    }
}
