provider "aws" {
  region = "eu-west-1"
}

locals {
  environment = "test11"
  label_order = ["name", "environment"]
}

module "logging_bucket" {
  source = "./../../"

  name        = "logging-s3-test"
  s3_name     = "zanq11"
  environment = local.environment
  label_order = local.label_order
  acl         = "log-delivery-write"
}

module "s3_bucket" {
  source        = "./../../"
  name          = "test-logging-bucket"
  s3_name       = "wewrrt"
  environment   = local.environment
  label_order   = local.label_order
  versioning    = true
  acl           = "private"
  logging       = true
  target_bucket = module.logging_bucket.id
  target_prefix = "logs"
  depends_on    = [module.logging_bucket]
}