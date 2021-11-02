pipeline {
    agent any
    tools {
       terraform 'Terrafrom-2'
    }
    parameters {
        string(name: 'WORKSPACE', defaultValue: 'development', description:'setting up workspace for terraform')
    }
    environment {
        TF_HOME = tool('Terrafrom-2')
        TP_LOG = "WARN"
        PATH = "$TF_HOME:$PATH"
        ACCESS_KEY = credentials('access_key')
        SECRET_KEY = credentials('secret_key')
    }
    stages {
            stage('TerraformInit'){
            steps {
                dir('/var/lib/jenkins/workspace/arshad/'){
                    sh "terraform init -input=false"
                    sh "echo \$PWD"
                    sh "whoami"
                }
            }
        }

        stage('TerraformFormat'){
            steps {
                dir('/var/lib/jenkins/workspace/arshad/'){
                    sh "terraform fmt -list=true -write=false -diff=true -check=true"
                }
            }
        }

        stage('TerraformValidate'){
            steps {
                dir('/var/lib/jenkins/workspace/arshad/'){
                    sh "terraform validate"
                }
            }
        }

        stage('TerraformPlan'){
            steps {
                dir('/var/lib/jenkins/workspace/arshad/'){
                    script {
                        try {
                            sh "terraform workspace new ${params.WORKSPACE}"
                        } catch (err) {
                            sh "terraform workspace select ${params.WORKSPACE}"
                        }
                        sh "terraform plan -var-file='params.WORKSPACE.dev.tfvars' -var 'access_key=$ACCESS_KEY' -var 'secret_key=$SECRET_KEY' \
                        -out devtfplan.out;echo \$? > status"
                        stash name: "terraform-plan", includes: "devtfplan.out"
                    }
                }
            }
        }
        
        stage('TerraformApply'){
            steps {
                script{
                    def apply = false
                    try {
                        input message: 'Can you please confirm the apply', ok: 'Ready to Apply the Config'
                        apply = true
                    } catch (err) {
                        apply = false
                         currentBuild.result = 'UNSTABLE'
                    }
                    if(apply){
                        dir('/var/lib/jenkins/workspace/arshad/'){
                            unstash "terraform-plan"
                            sh 'terraform apply "devtfplan.out"' 
                        }
                    }
                }
            }
        }
    }
}
