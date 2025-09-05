// Basic Syntax

pipeline {
    // Pre-build section
    agent { label 'AGENT-1' }

    environment {
        ENV_NAME = "Jenkins-practice"
    }

    options {
        timeout(time: 30, unit: 'MINUTES') 
        disableConcurrentBuilds()
        retry(2)
    }

    parameters {
        string(name: 'PERSON', defaultValue: 'PavanDivi', description: 'Who should I say hello to?')
        text(name: 'BIOGRAPHY', defaultValue: 'DevOps Engineer', description: 'Enter some information about the person')
        booleanParam(name: 'TOGGLE', defaultValue: true, description: 'Toggle this value')
        choice(name: 'CHOICE', choices: ['One', 'Two', 'Three'], description: 'Pick something')
        password(name: 'PASSWORD', defaultValue: 'Test2', description: 'Enter a password')
        string(name: 'ENV', defaultValue: 'dev', description: 'Which environment to deploy?')
    }

    // Build section (stages)
    stages {
        stage('Build') {
            steps {
                script {
                    sh '''
                        echo "Building Stage"
                        env
                    '''
                }
            }
        }

        stage('Test') {
            steps {
                echo "Testing Stage"
            }
        }

        stage('Deploy') {
            input {
                message "Should we continue?"
                ok "Yes, we should."
                submitter "alice,bob"
                parameters {
                    string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
                }
            }
            steps {
                script {
                    // Use Elvis operator for safe ENV selection
                    def targetEnv = params.ENV ?: "dev"
                    echo "Deploying to environment: ${targetEnv}"
                    echo "Hello, ${params.PERSON}, nice to meet you."
                }
            }
        }

        stage('Parameters') {
            steps {
                echo "Hello ${params.PERSON}"
                echo "Biography: ${params.BIOGRAPHY}"
                echo "Toggle: ${params.TOGGLE}"
                echo "Choice: ${params.CHOICE}"
                echo "Password: ${params.PASSWORD}"
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
