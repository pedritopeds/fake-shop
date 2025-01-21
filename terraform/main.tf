terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.84.0"
    }
  }
}

provider "aws" {
   region = "us-east-1"
}

module "vpc" {

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.17.0"

  name = "minha-vpc"
  cidr = "10.0.0.0/16"

  azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = true

  private_subnet_tags = {
    Name                                    = format("%s-sub-private", var.eks_name),
    "kubernetes.io/role/internal-elb"       = 1,
    "kubernetes.io/cluster/${var.eks_name}" = "shared"
  }

  public_subnet_tags = {
    "Name"                                  = format("%s-sub-public", var.eks_name),
    "kubernetes.io/role/elb"                = 1,
    "kubernetes.io/cluster/${var.eks_name}" = "shared"
  }

}

module "eks" {
  
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.0"

  cluster_name                             = var.eks_name
  cluster_version                          = var.eks_version
  subnet_ids                               = module.vpc.private_subnets
  vpc_id                                   = module.vpc.vpc_id
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    live = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.medium"]
    }
  }
}

variable "eks_name" {
  default = "aula-k8s"
}

variable "eks_version" {
  default = "1.31"
}