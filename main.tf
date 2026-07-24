module "vpc" {
  source       = "./modules/vpc"
  project      = var.project
  vpc_cidr     = var.vpc_cidr
  aws_region   = var.aws_region
  cluster_name = var.cluster_name
}

module "eks" {
  source             = "./modules/eks"
  project            = var.project
  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  node_instance_type = var.node_instance_type
  desired_nodes      = var.desired_nodes
  min_nodes          = var.min_nodes
  max_nodes          = var.max_nodes
}