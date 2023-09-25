provider "aws" {
  region = "eu-west-1"
}

locals {
  environment = "test"
  label_order = ["name", "environment"]
}

module "s3_bucket" {
  source      = "./../../"
  name        = "test-secure-bucket"
  environment = local.environment
  label_order = local.label_order
  s3_name     = "sdfdfg"
  versioning  = true

  acl = "private"
  cors_rule = [{
    allowed_headers = ["*"],
    allowed_methods = ["PUT", "POST"],
    allowed_origins = ["https://s3-website-test.hashicorp.com"],
    expose_headers  = ["ETag"],
    max_age_seconds = 3000
  }]
}
