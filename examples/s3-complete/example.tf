provider "aws" {
  region = "eu-west-1"
}

locals {
  environment        = "test"
  label_order        = ["name", "environment"]
  availability_zones = ["eu-west-1a", "eu-west-1b"]
}

data "aws_canonical_user_id" "current" {}

module "logging_bucket" {
  source = "./../../"

  name        = "logging-x13"
  environment = local.environment
  label_order = local.label_order
  s3_name     = ""
  acl         = "log-delivery-write"
}

module "vpc" {
  source      = "git::git@github.com:opz0/terraform-aws-vpc.git?ref=master"
  name        = "app"
  environment = local.environment
  cidr_block  = "172.16.0.0/16"
}

module "subnets" {
  source             = "git::git@github.com:opz0/terraform-aws-subnet.git?ref=master"
  name               = "subnet"
  environment        = local.environment
  availability_zones = local.availability_zones
  vpc_id             = module.vpc.id
  cidr_block         = module.vpc.vpc_cidr_block
  type               = "private"
  igw_id             = module.vpc.igw_id
  ipv6_cidr_block    = module.vpc.ipv6_cidr_block
}

module "kms_key" {
  source                  = "git::git@github.com:opz0/terraform-aws-kms.git?ref=master"
  name                    = "kms"
  environment             = local.environment
  label_order             = local.label_order
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

  name        = "arcx-13"
  environment = local.environment
  label_order = local.label_order
  s3_name     = "sedfdrg"

  acceleration_status = true
  request_payer       = "BucketOwner"
  object_lock_enabled = true

  logging       = true
  target_bucket = module.logging_bucket.id
  target_prefix = "logs"

  enable_server_side_encryption = true
  enable_kms                    = true
  kms_master_key_id             = module.kms_key.key_arn

  object_lock_configuration = {
    mode  = "GOVERNANCE"
    days  = 366
    years = null
  }

  versioning = true
  vpc_endpoints = [
    {
      endpoint_count = 1
      vpc_id         = module.vpc.id
      service_type   = "Interface"
      subnet_ids     = module.subnets.private_subnet_id
    },
    {
      endpoint_count = 2
      vpc_id         = module.vpc.id
      service_type   = "Gateway"
    }
  ]

  intelligent_tiering = {
    general = {
      status = "Enabled"
      filter = {
        prefix = "/"
        tags = {
          Environment = "dev"
        }
      }
      tiering = {
        ARCHIVE_ACCESS = {
          days = 180
        }
      }
    },
    documents = {
      status = false
      filter = {
        prefix = "documents/"
      }
      tiering = {
        ARCHIVE_ACCESS = {
          days = 125
        }
        DEEP_ARCHIVE_ACCESS = {
          days = 200
        }
      }
    }
  }

  metric_configuration = [
    {
      name = "documents"
      filter = {
        prefix = "documents/"
        tags = {
          priority = "high"
        }
      }
    },
    {
      name = "other"
      filter = {
        tags = {
          production = "true"
        }
      }
    },
    {
      name = "all"
    }
  ]


  cors_rule = [{
    allowed_headers = ["*"],
    allowed_methods = ["PUT", "POST"],
    allowed_origins = ["https://s3-website-test.hashicorp.com"],
    expose_headers  = ["ETag"],
    max_age_seconds = 3000
  }]


  grants = [
    {
      id          = null
      type        = "Group"
      permissions = ["READ", "WRITE"]
      uri         = "http://acs.amazonaws.com/groups/s3/LogDelivery"
    },
  ]
  owner_id = data.aws_canonical_user_id.current.id


  enable_lifecycle_configuration_rules = true
  lifecycle_configuration_rules = [
    {
      id                                             = "log"
      prefix                                         = null
      enabled                                        = true
      tags                                           = { "temp" : "true" }
      enable_glacier_transition                      = false
      enable_deeparchive_transition                  = false
      enable_standard_ia_transition                  = false
      enable_current_object_expiration               = true
      enable_noncurrent_version_expiration           = true
      abort_incomplete_multipart_upload_days         = null
      noncurrent_version_glacier_transition_days     = 0
      noncurrent_version_deeparchive_transition_days = 0
      noncurrent_version_expiration_days             = 30
      standard_transition_days                       = 0
      glacier_transition_days                        = 0
      deeparchive_transition_days                    = 0
      storage_class                                  = "GLACIER"
      expiration_days                                = 365
    },
    {
      id                                             = "log1"
      prefix                                         = null
      enabled                                        = true
      tags                                           = {}
      enable_glacier_transition                      = false
      enable_deeparchive_transition                  = false
      enable_standard_ia_transition                  = false
      enable_current_object_expiration               = true
      enable_noncurrent_version_expiration           = true
      abort_incomplete_multipart_upload_days         = 1
      noncurrent_version_glacier_transition_days     = 0
      noncurrent_version_deeparchive_transition_days = 0
      storage_class                                  = "DEEP_ARCHIVE"
      noncurrent_version_expiration_days             = 30
      standard_transition_days                       = 0
      glacier_transition_days                        = 0
      deeparchive_transition_days                    = 0
      expiration_days                                = 365
    }
  ]


  website = {
    index_document = "index.html"
    error_document = "error.html"
    routing_rules = [{
      condition = {
        key_prefix_equals = "docs/"
      },
      redirect = {
        replace_key_prefix_with = "documents/"
      }
      }, {
      condition = {
        http_error_code_returned_equals = 404
        key_prefix_equals               = "archive/"
      },
      redirect = {
        host_name          = "archive.myhost.com"
        http_redirect_code = 301
        protocol           = "https"
        replace_key_with   = "not_found.html"
      }
    }]
  }
}
