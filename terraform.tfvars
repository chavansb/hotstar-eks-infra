aws_region         = "ap-south-1"
project            = "hotstar"
cluster_name       = "hotstar-eks-cluster"
vpc_cidr           = "10.0.0.0/16"
node_instance_type = "t3.small" # added this as it free version
desired_nodes      = 1
min_nodes          = 1
max_nodes          = 2
