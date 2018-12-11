pipeline {
    agent any
    stages {
        stage('Prepare infrastructure'){
            steps {
                sh "wget https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip"
                sh "unzip terraform_0.11.10_linux_amd64.zip"
                sh "chmod +x terraform"
                sh "./terraform init"
            } 
        }
        stage('Build infrastructure'){
            steps{
                sh "./terraform apply --auto-approve"
            }
        }
    }

}