provider "aws" {
  region = "eu-west-1"
}

locals {
  environment = "test11"
  label_order = ["name", "environment"]
}

module "kms_key" {
  source      = "git::https://github.com/opz0/terraform-aws-kms.git?ref=v1.0.0"
  name        = "kms11"
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

  name        = "test-encryption-bucket"
  s3_name     = "dmzx"
  environment = local.environment
  label_order = local.label_order

  acl                           = "private"
  enable_server_side_encryption = true
  versioning                    = true
  enable_kms                    = true
  kms_master_key_id             = module.kms_key.key_arn
}
