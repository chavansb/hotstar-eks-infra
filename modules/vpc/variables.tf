variable "project" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}