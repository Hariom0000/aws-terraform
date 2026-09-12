// Development frontend stack; calls the static website module.
# environments/dev/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "aws-dev-profile" # Enforces deployment to Dev AWS profile environment
}

module "frontend_dev" {
  source              = "../../modules/static_website"
  bucket_name         = "dev-handsonlab-s3"
  domain_name         = "handsonlab.space" 
  acm_certificate_arn = "arn:aws:acm:us-east-1:590183823048:certificate/967e33f8-9e9a-4c21-a546-65ff3981643b"
}
