provider "aws" {
  region = "eu-west-1"
}

locals {
  environment = "test12"
  label_order = ["name", "environment"]
}

module "logging_bucket" {
  source = "./../../"

  name        = "logging"
  s3_name     = "quya"
  environment = local.environment
  label_order = local.label_order
  acl         = "log-delivery-write"
}

module "kms_key" {
  source      = "git::https://github.com/cypik/terraform-aws-kms.git?ref=v1.0.0"
  name        = "kms12"
  environment = local.environment
  label_order = local.label_order

  enabled                 = true
  description             = "KMS key for s3"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  alias                   = "alias/s33"
  policy                  = data.aws_iam_policy_document.default.json
}

data "aws_iam_policy_document" "default" {
  version = "2012-10-17"
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

module "s3_bucket" {
  source = "./../../"

  name        = "test-logging-encryption-bucket"
  s3_name     = "aqua12"
  environment = local.environment
  label_order = local.label_order

  versioning                    = true
  acl                           = "private"
  enable_server_side_encryption = true
  enable_kms                    = true
  kms_master_key_id             = module.kms_key.key_arn
  logging                       = true
  target_bucket                 = module.logging_bucket.id
  target_prefix                 = "logs"
  depends_on                    = [module.logging_bucket]
}
