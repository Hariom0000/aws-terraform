// Development frontend stack; calls the static website module.
# environments/dev/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "handsonlab-tfstate-storage-dev"
    key    = "dev/frontend/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "handsonlab-tflocks-dev"
    encrypt        = true
  }
}


provider "aws" {
  region  = "us-east-1"
  #profile = "aws-dev-profile" # Enforces deployment to Dev AWS profile environment
}

module "frontend_dev" {
  source              = "../../modules/static_website"
  bucket_name         = "dev-handsonlab-s3"
  domain_name         = "handsonlab.space" 
  acm_certificate_arn = "arn:aws:acm:us-east-1:533267148411:certificate/390c5d3b-7976-4b98-9162-ba77c11f33e1"
}
