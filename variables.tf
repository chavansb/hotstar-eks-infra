variable "aws_region" {
  default = "ap-south-1"
}

variable "project" {
  default = "hotstar"
}

variable "cluster_name" {
  default = "hotstar-eks-cluster"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "node_instance_type" {
  default = "t3.medium"
}

variable "desired_nodes" {
  default = 2
}

variable "min_nodes" {
  default = 1
}

variable "max_nodes" {
  default = 3
}