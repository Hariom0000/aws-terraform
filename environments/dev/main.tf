// Development frontend stack; calls the static website module.
# environments/dev/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket         = "handsonlab-tfstate-storage-dev"
    key            = "dev/frontend/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "handsonlab-tflocks-dev"
    encrypt        = true
  }
}


provider "aws" {
  region = "us-east-1"
  #profile = "aws-dev-profile" # Enforces deployment to Dev AWS profile environment
}

variable "backend_origin_domain_name" {
  description = "The DNS name of the EKS ALB used for /api/* requests"
  type        = string
  default     = null
}

module "vpc" {
  source      = "../../modules/vpc"
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
}

module "eks" {
  source             = "../../modules/eks"
  environment        = "dev"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

# 3. Secure Relational Storage Data Layer
module "database" {
  source                = "../../modules/db"
  environment           = "dev"
  vpc_id                = module.vpc.vpc_id
  data_subnet_ids       = module.vpc.data_subnet_ids
  eks_security_group_id = module.eks.cluster_security_group_id # Feeds EKS SG into Postgres rules!
}

module "container_registry" {
  source      = "../../modules/container_registry"
  environment = "dev"
}

# 4. Global Edge Presentation Frontend Layer (Your S3/CloudFront)
module "frontend_dev" {
  source                     = "../../modules/static_website"
  bucket_name                = "dev-handsonlab-s3"
  domain_name                = "handsonlab.space"
  acm_certificate_arn        = "arn:aws:acm:us-east-1:718465053830:certificate/411ccbba-3a8a-459b-a2d0-4b82813df7c8"
  backend_origin_domain_name = var.backend_origin_domain_name
}

/*module "frontend_dev" {
  source              = "../../modules/static_website"
  bucket_name         = "dev-handsonlab-s3"
  domain_name         = "handsonlab.space"
  acm_certificate_arn = "arn:aws:acm:us-east-1:533267148411:certificate/390c5d3b-7976-4b98-9162-ba77c11f33e1"
}*/
