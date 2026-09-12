variable "bucket_name" {
  description = "The unique name of the S3 bucket for web assets"
  type        = string
}

variable "domain_name" {
  description = "The root domain name (e.g., handsonlab.space)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the pre-generated ACM certificate in us-east-1"
  type        = string
}