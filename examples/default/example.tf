provider "aws" {
  region = "eu-west-1"
}

locals {
  environment = "test"
  label_order = ["name", "environment"]
}

module "s3_bucket" {
  source = "./../../"

  name        = "test-secure-bucket"
  environment = local.environment
  label_order = local.label_order
  s3_name     = "cdkc"
  acl         = "private"
  versioning  = true
}