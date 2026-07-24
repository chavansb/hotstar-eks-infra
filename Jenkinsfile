pipeline {
    agent any

    parameters {
        choice(
            name: 'action',
            choices: ['apply', 'destroy'],
            description: '''Select Terraform action:
            apply   = Create/update EKS cluster
            destroy = Destroy all infrastructure'''
        )
    }

    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        CLUSTER_NAME       = 'hotstar-eks-cluster'
        TF_IN_AUTOMATION   = 'true'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/chavansb/hotstar-eks-infra.git'
                sh 'ls -la'
                echo "✅ Code checked out from main branch"
            }
        }

        stage('Configure AWS') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region $AWS_DEFAULT_REGION
                        aws sts get-caller-identity
                        echo "✅ AWS configured successfully"
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        terraform init
                        echo "✅ Terraform initialized"
                    '''
                }
            }
        }

        stage('Terraform Format Check') {
            steps {
                sh '''
                    terraform fmt -check -recursive
                    echo "✅ Format check passed"
                '''
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        terraform validate
                        echo "✅ Terraform config is valid"
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.action == 'apply' }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                        def rc = sh(
                            script: "terraform plan -detailed-exitcode -out=tfplan",
                            returnStatus: true
                        )
                        if (rc == 0) {
                            echo "ℹ️ No infrastructure changes detected"
                            env.TF_CHANGES = "false"
                        } else if (rc == 2) {
                            echo "⚠️ Infrastructure changes detected"
                            env.TF_CHANGES = "true"
                        } else {
                            error "❌ Terraform plan failed"
                        }
                    }
                }
            }
        }

        stage('Approval Before Apply') {
            when {
                allOf {
                    expression { params.action == 'apply' }
                    expression { env.TF_CHANGES == "true" }
                }
            }
            steps {
                input message: """
                ⚠️ REVIEW TERRAFORM PLAN ABOVE
                This will create/update:
                - VPC + subnets + IGW + NAT Gateway
                - EKS cluster: hotstar-eks-cluster
                - Worker node group (t3.medium x2)
                Estimated cost: ~₹50-60/hr
                Approve to proceed?
                """
            }
        }

        stage('Terraform Apply') {
            when {
                allOf {
                    expression { params.action == 'apply' }
                    expression { env.TF_CHANGES == "true" }
                }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        terraform apply --auto-approve tfplan
                        echo "✅ Infrastructure created successfully"
                    '''
                }
            }
        }

        stage('Configure EKS Access') {
            when {
                allOf {
                    expression { params.action == 'apply' }
                    expression { env.TF_CHANGES == "true" }
                }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        CALLER=$(aws sts get-caller-identity --query Arn --output text)
                        echo "Logged in as: $CALLER"

                        aws eks create-access-entry \
                          --cluster-name $CLUSTER_NAME \
                          --principal-arn $CALLER \
                          --type STANDARD \
                          --region $AWS_DEFAULT_REGION || echo "Access entry may already exist"

                        aws eks associate-access-policy \
                          --cluster-name $CLUSTER_NAME \
                          --principal-arn $CALLER \
                          --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
                          --access-scope '{"type":"cluster"}' \
                          --region $AWS_DEFAULT_REGION || echo "Policy may already be associated"

                        aws eks update-kubeconfig \
                          --name $CLUSTER_NAME \
                          --region $AWS_DEFAULT_REGION

                        echo "Waiting 30s for nodes to be ready..."
                        sleep 30
                        kubectl get nodes
                        echo "✅ EKS cluster is ready!"
                    '''
                }
            }
        }

        stage('Approval Before Destroy') {
            when {
                expression { params.action == 'destroy' }
            }
            steps {
                input message: """
                🚨 WARNING — DESTRUCTIVE ACTION
                This will PERMANENTLY DELETE:
                - EKS cluster: hotstar-eks-cluster
                - All worker nodes
                - VPC + all subnets
                - NAT Gateway (stops billing)
                Are you absolutely sure?
                """
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.action == 'destroy' }
            }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        terraform destroy --auto-approve
                        echo "✅ All infrastructure destroyed"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo """
            ========================================
            ✅ Pipeline completed successfully!
            Action: ${params.action}
            Cluster: ${CLUSTER_NAME}
            Region: ${AWS_DEFAULT_REGION}
            ========================================
            """
        }
        failure {
            echo """
            ========================================
            ❌ Pipeline FAILED
            Check logs above for details
            ========================================
            """
        }
        always {
            cleanWs()
        }
    }
}
