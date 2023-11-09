# Terraform-aws-s3 

# AWS Infrastructure Provisioning with Terraform

## Table of Contents
- [Introduction](#introduction)
- [Usage](#usage)
- [Module Inputs](#module-inputs)
- [Module Outputs](#module-outputs)
- [License](#license)

## Introduction
This project deploys a Google Cloud infrastructure using Terraform to create aws-s3 .
## Usage
To use this module, you should have Terraform installed and configured for AWS. This module provides the necessary Terraform configuration for creating AWS resources, and you can customize the inputs as needed. Below is an example of how to use this module:
## Examples

## Example: Default

```hcl
module "s3_bucket" {
  source      = "git::https://github.com/opz0/terraform-aws-s3.git?ref=v1.0.0"
  name        = "test-secure-bucket"
  environment = local.environment
  label_order = local.label_order
  s3_name     = "cdkc"
  acl         = "private"
  versioning  = true
}
```

## Example: s3 complete
```hcl
module "s3_bucket" {
  source = "git::https://github.com/opz0/terraform-aws-s3.git?ref=v1.0.0"
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
      vpc_id         = module.vpc.vpc_id
      service_type   = "Interface"
      subnet_ids     = module.subnets.private_subnet_id
    },
    {
      endpoint_count = 2
      vpc_id         = module.vpc.vpc_id
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
```

## Example: s3-with-core-rule

```hcl
module "s3_bucket" {
  source      = "git::https://github.com/opz0/terraform-aws-s3.git?ref=v1.0.0"
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
```

## Example: s3-with-encryption

```hcl
module "s3_bucket" {
  source = "git::https://github.com/opz0/terraform-aws-s3.git?ref=v1.0.0"

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
```
## Example: s3-with-logging

```hcl
module "s3_bucket" {
source        = "git::https://github.com/opz0/terraform-aws-s3.git?ref=v1.0.0"
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
```
## Example: s3-with-logging-encryption

```hcl
module "s3_bucket" {
  source = "git::https://github.com/opz0/terraform-aws-s3.git?ref=v1.0.0"
  name        = "test-logging-encryption-bucket"
  s3_name     = "aqua"
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
```

## Example: s3-with-repliccation

```hcl
module "s3_bucket" {
  source      = "git::https://github.com/opz0/terraform-aws-s3.git?ref=v1.0.0"
  name        = "test-s3"
  s3_name     = "poxord"
  environment = local.environment
  label_order = local.label_order

  acl = "private"
  replication_configuration = {
    role       = aws_iam_role.replication.arn
    versioning = true

    rules = [
      {
        id                        = "something-with-kms-and-filter"
        status                    = true
        priority                  = 10
        delete_marker_replication = false
        source_selection_criteria = {
          replica_modifications = {
            status = "Enabled"
          }
          sse_kms_encrypted_objects = {
            enabled = true
          }
        }
        filter = {
          prefix = "one"
          tags = {
            ReplicateMe = "Yes"
          }
        }
        destination = {
          bucket             = "arn:aws:s3:::${module.replica_bucket.id}"
          storage_class      = "STANDARD"
          replica_kms_key_id = aws_kms_key.replica.arn
          account_id         = data.aws_caller_identity.current.account_id
          access_control_translation = {
            owner = "Destination"
          }
          replication_time = {
            status  = "Enabled"
            minutes = 15
          }
          metrics = {
            status  = "Enabled"
            minutes = 15
          }
        }
      },
      {
        id                        = "something-with-filter"
        priority                  = 20
        delete_marker_replication = false
        filter = {
          prefix = "two"
          tags = {
            ReplicateMe = "Yes"
          }
        }
        destination = {
          bucket        = "arn:aws:s3:::${module.replica_bucket.id}"
          storage_class = "STANDARD"
        }
      },
      {
        id                        = "everything-with-filter"
        status                    = "Enabled"
        priority                  = 30
        delete_marker_replication = true
        1 = {
          prefix = ""
        }
        destination = {
          bucket        = "arn:aws:s3:::${module.replica_bucket.id}"
          storage_class = "STANDARD"
        }
      },
      {
        id                        = "everything-without-filters"
        status                    = "Enabled"
        delete_marker_replication = true
        destination = {
          bucket        = "arn:aws:s3:::${module.replica_bucket.id}"
          storage_class = "STANDARD"
        }
      },
    ]
  }
}
```

## Module Inputs
- `name`: The name you want to assign to this access point.
- `environment`: The environment for your application.
- `acceleration_status`: Sets the accelerate configuration of an existing bucket. Can be Enabled or Suspended
- `kms_master_key_id`:The AWS KMS master key ID used for the SSE-KMS encryption.
- `cors_rule`:  A rule of Cross-Origin Resource Sharing (documented below).
- `acl`: The canned ACL to apply. Defaults to "private". Conflicts with grant.
- `logging`: A settings of bucket logging.
- For security group settings, you can configure the ingress and egress rules using variables like:

## Module Outputs
- `id` : Unique identifier for the rule.
- `tags` : A map of tags to assign to the bucket.
- `arn` : The ARN of the bucket. Will be of format
- `bucket_domain_name`: The bucket domain name. Will be of format
- Other relevant security group outputs (modify as needed).

## Examples
For detailed examples on how to use this module, please refer to the 'examples' directory within this repository.

## Author
Your Name Replace '[License Name]' and '[Your Name]' with the appropriate license and your information. Feel free to expand this README with additional details or usage instructions as needed for your specific use case.

## License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/opz0/terraform-aws-s3.git/blob/readme/LICENSE) file for details.
