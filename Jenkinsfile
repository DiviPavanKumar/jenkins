// Basic Syntax
pipeline {
    agent { label 'AGENT-1' }
    stages {
        stage ('Build') {
            steps {
                echo "Building Stage"
            }
        }
         stage ('Test') {
            steps {
                echo "Testing Stage"
            }
         }
         stage ('Deploy') {
            steps {
                echo "Deploying Stage"
            }
         }  
         post { 
            always { 
            echo 'I will always say Hello again!'
        }
        changed {
            echo 'current Pipeline’s run has a different completion status from its previous run'
        }
        failure {
            echo 'pipeline Failed'
        }
        success {
            echo 'pipline Success'
        }
    } 
        }
    }