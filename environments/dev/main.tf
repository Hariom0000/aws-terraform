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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
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

data "aws_eks_cluster_auth" "dev" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.dev.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.dev.token
  }
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

resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = module.eks.load_balancer_controller_role_arn
    }
  }

  depends_on = [module.eks]
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "region"
    value = "us-east-1"
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].name
  }

  depends_on = [module.eks, kubernetes_service_account_v1.aws_load_balancer_controller]
}

resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "app-ingress"
    namespace = "default"

    annotations = {
      "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"  = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{ HTTP = 80 }])
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "app-service"

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.aws_load_balancer_controller]
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

import {
  to = module.container_registry.aws_ecr_repository.backend
  id = "dev-backend-service"
}

# 4. Global Edge Presentation Frontend Layer (Your S3/CloudFront)
module "frontend_dev" {
  source                     = "../../modules/static_website"
  bucket_name                = "dev-handsonlab-s3"
  domain_name                = "handsonlab.space"
  acm_certificate_arn        = "arn:aws:acm:us-east-1:106220368686:certificate/59786f67-9d27-4df7-b6f9-98a1b90469c8"
  backend_origin_domain_name = var.backend_origin_domain_name
}

/*module "frontend_dev" {
  source              = "../../modules/static_website"
  bucket_name         = "dev-handsonlab-s3"
  domain_name         = "handsonlab.space"
  acm_certificate_arn = "arn:aws:acm:us-east-1:533267148411:certificate/390c5d3b-7976-4b98-9162-ba77c11f33e1"
}*/
