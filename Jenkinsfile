pipeline {
    agent { label 'AGENT-1' }
    
    environment { 
        Subject = 'Jenkins-CI'
    }

    options {
        timeout(time: 1, unit: 'MINUTES') 
        disableConcurrentBuilds()
        retry(2)
    }

    parameters {

        string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
        text(name: 'BIOGRAPHY', defaultValue: '', description: 'Enter some information about the person')
        booleanParam(name: 'TOGGLE', defaultValue: true, description: 'Toggle this value')
        choice(name: 'CHOICE', choices: ['One', 'Two', 'Three'], description: 'Pick something')
        password(name: 'PASSWORD', defaultValue: 'SECRET', description: 'Enter a password')
    
    }

    // Build
    stages {
        stage('Build') {
            steps {
                script {
                sh """
                echo "Hello Build..."
                env
                echo "Hello ${params.PERSON}"
                echo "Triggers: after github-webhook setup"
                """
                }
            }
        }
        stage('Test') {
            steps {
                script {
                echo 'Testing..'
                }
            }
        }
        stage('Deploy') {
            steps {
                script {
                echo 'Deploying....'
                }
            }
        }
        stage('Example') {
            steps {
                echo "Hello ${params.PERSON}"

                echo "Biography: ${params.BIOGRAPHY}"

                echo "Toggle: ${params.TOGGLE}"

                echo "Choice: ${params.CHOICE}"

                echo "Password: ${params.PASSWORD}"
            }
        }
    }

    post { 
        always { 
            echo 'I will always say Hello again!'
            deleteDir()
        }

        success { 
            echo 'hello success'
        }

        failure { 
            echo 'hello Failed'
        }
    }
}
