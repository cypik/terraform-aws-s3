# Terraform version
terraform {
  required_version = ">=1.12.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.82.2"
    }
  }
}