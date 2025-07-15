# Terraform-aws-s3

# Terraform AWS Cloud s3 Module


## Table of Contents
- [Introduction](#introduction)
- [Usage](#usage)
- [Examples](#Examples)
- [Author](#Author)
- [License](#license)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Introduction
This Terraform module creates an AWS Simple Storage Service (s3) along with additional configuration options.
## Usage
To use this module, you should have Terraform installed and configured for AWS. This module provides the necessary Terraform configuration for creating AWS resources, and you can customize the inputs as needed. Below is an example of how to use this module:
## Examples

## Example: Default

```hcl
module "s3_bucket" {
  source      = "cypik/s3/aws"
  version     = "1.0.3"
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
  source      = "cypik/s3/aws"
  version     = "1.0.3"
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

  versioning    = true
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
  source      = "cypik/s3/aws"
  version     = "1.0.3"
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
  source      = "cypik/s3/aws"
  version     = "1.0.3"
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
  source      = "cypik/s3/aws"
  version     = "1.0.3"
  name        = "test-logging-bucket"
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
  source      = "cypik/s3/aws"
  version     = "1.0.3"
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
  source      = "cypik/s3/aws"
  version     = "1.0.3"
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

## Examples
For detailed examples on how to use this module, please refer to the [Examples](https://github.com/cypik/terraform-aws-s3/tree/master/examples) directory within this repository.

## Author
Your Name Replace **MIT** and **Cypik** with the appropriate license and your information. Feel free to expand this README with additional details or usage instructions as needed for your specific use case.

## License
This project is licensed under the **MIT** License - see the [LICENSE](https://github.com/cypik/terraform-aws-s3/blob/master/LICENSE) file for details.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5.67.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=5.67.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_labels"></a> [labels](#module\_labels) | cypik/labels/aws | 1.0.2 |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.s3_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_accelerate_configuration.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_accelerate_configuration) | resource |
| [aws_s3_bucket_acl.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_analytics_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_analytics_configuration) | resource |
| [aws_s3_bucket_cors_configuration.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_intelligent_tiering_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_intelligent_tiering_configuration) | resource |
| [aws_s3_bucket_inventory.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_inventory) | resource |
| [aws_s3_bucket_lifecycle_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_metric.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_metric) | resource |
| [aws_s3_bucket_object_lock_configuration.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.block-http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.s3_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_replication_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration) | resource |
| [aws_s3_bucket_request_payment_configuration.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_request_payment_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_website_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
| [aws_vpc_endpoint.endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_service.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acceleration_status"></a> [acceleration\_status](#input\_acceleration\_status) | Sets the accelerate configuration of an existing bucket. Can be Enabled or Suspended | `bool` | `false` | no |
| <a name="input_acl"></a> [acl](#input\_acl) | Canned ACL to apply to the S3 bucket. | `string` | `null` | no |
| <a name="input_acl_grants"></a> [acl\_grants](#input\_acl\_grants) | A list of policy grants for the bucket. Conflicts with `acl`. Set `acl` to `null` to use this. | <pre>list(object({<br/>    id         = string<br/>    type       = string<br/>    permission = string<br/>    uri        = string<br/>  }))</pre> | `null` | no |
| <a name="input_analytics_configuration"></a> [analytics\_configuration](#input\_analytics\_configuration) | Map containing bucket analytics configuration. | `any` | `{}` | no |
| <a name="input_attach_public_policy"></a> [attach\_public\_policy](#input\_attach\_public\_policy) | Controls if a user defined public bucket policy will be attached (set to `false` to allow upstream to apply defaults to the bucket) | `bool` | `true` | no |
| <a name="input_aws_iam_policy_document"></a> [aws\_iam\_policy\_document](#input\_aws\_iam\_policy\_document) | The text of the policy. Although this is a bucket policy rather than an IAM policy, the aws\_iam\_policy\_document data source may be used, so long as it specifies a principal. For more information about building AWS IAM policy documents with Terraform, see the AWS IAM Policy Document Guide. Note: Bucket policies are limited to 20 KB in size. | `string` | `""` | no |
| <a name="input_block_public_acls"></a> [block\_public\_acls](#input\_block\_public\_acls) | Whether Amazon S3 should block public ACLs for this bucket. | `bool` | `true` | no |
| <a name="input_block_public_policy"></a> [block\_public\_policy](#input\_block\_public\_policy) | Whether Amazon S3 should block public bucket policies for this bucket. | `bool` | `true` | no |
| <a name="input_bucket_policy"></a> [bucket\_policy](#input\_bucket\_policy) | Conditionally create S3 bucket policy. | `bool` | `false` | no |
| <a name="input_bucket_prefix"></a> [bucket\_prefix](#input\_bucket\_prefix) | (Optional, Forces new resource) Creates a unique bucket name beginning with the specified prefix. | `string` | `null` | no |
| <a name="input_configuration_status"></a> [configuration\_status](#input\_configuration\_status) | Versioning state of the bucket. Valid values: Enabled, Suspended, or Disabled. Disabled should only be used when creating or importing resources that correspond to unversioned S3 buckets. | `string` | `"Suspended"` | no |
| <a name="input_control_object_ownership"></a> [control\_object\_ownership](#input\_control\_object\_ownership) | Whether to manage S3 Bucket Ownership Controls on this bucket. | `bool` | `false` | no |
| <a name="input_cors_rule"></a> [cors\_rule](#input\_cors\_rule) | CORS Configuration specification for this bucket | <pre>list(object({<br/>    allowed_headers = list(string)<br/>    allowed_methods = list(string)<br/>    allowed_origins = list(string)<br/>    expose_headers  = list(string)<br/>    max_age_seconds = number<br/>  }))</pre> | `null` | no |
| <a name="input_enable_kms"></a> [enable\_kms](#input\_enable\_kms) | Enable enable\_server\_side\_encryption | `bool` | `false` | no |
| <a name="input_enable_lifecycle_configuration_rules"></a> [enable\_lifecycle\_configuration\_rules](#input\_enable\_lifecycle\_configuration\_rules) | enable or disable lifecycle\_configuration\_rules | `bool` | `false` | no |
| <a name="input_enable_server_side_encryption"></a> [enable\_server\_side\_encryption](#input\_enable\_server\_side\_encryption) | Enable enable\_server\_side\_encryption | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Conditionally create S3 bucket. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (e.g. `prod`, `dev`, `staging`). | `string` | `""` | no |
| <a name="input_expected_bucket_owner"></a> [expected\_bucket\_owner](#input\_expected\_bucket\_owner) | (Optional) Account ID of the expected bucket owner. | `string` | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. These objects are not recoverable. | `bool` | `false` | no |
| <a name="input_grantee_email"></a> [grantee\_email](#input\_grantee\_email) | (Optional) Email address of the grantee. | `string` | `null` | no |
| <a name="input_grantee_id"></a> [grantee\_id](#input\_grantee\_id) | (Optional) Canonical user ID of the grantee. | `string` | `null` | no |
| <a name="input_grantee_type"></a> [grantee\_type](#input\_grantee\_type) | (Optional) Type of the grantee. Valid values: CanonicalUser, AmazonCustomerByEmail, Group. | `string` | `"CanonicalUser"` | no |
| <a name="input_grantee_uri"></a> [grantee\_uri](#input\_grantee\_uri) | (Optional) URI of the grantee group. | `string` | `null` | no |
| <a name="input_grants"></a> [grants](#input\_grants) | ACL Policy grant.conflict with acl.set acl null to use this | <pre>list(object({<br/>    id          = string<br/>    type        = string<br/>    permissions = list(string)<br/>    uri         = string<br/>  }))</pre> | `null` | no |
| <a name="input_ignore_public_acls"></a> [ignore\_public\_acls](#input\_ignore\_public\_acls) | Whether Amazon S3 should ignore public ACLs for this bucket. | `bool` | `true` | no |
| <a name="input_intelligent_tiering"></a> [intelligent\_tiering](#input\_intelligent\_tiering) | Map containing intelligent tiering configuration. | `any` | `{}` | no |
| <a name="input_inventory_configuration"></a> [inventory\_configuration](#input\_inventory\_configuration) | Map containing S3 inventory configuration. | `any` | `{}` | no |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | The AWS KMS master key ID used for the SSE-KMS encryption. This can only be used when you set the value of sse\_algorithm as aws:kms. The default aws/s3 AWS KMS master key is used if this element is absent while the sse\_algorithm is aws:kms. | `string` | `""` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | Label order, e.g. `name`,`Environment`. | `list(any)` | <pre>[<br/>  "name",<br/>  "environment"<br/>]</pre> | no |
| <a name="input_lifecycle_configuration_rules"></a> [lifecycle\_configuration\_rules](#input\_lifecycle\_configuration\_rules) | A list of lifecycle rules | <pre>list(object({<br/>    id      = string<br/>    prefix  = string<br/>    enabled = bool<br/>    tags    = map(string)<br/><br/>    enable_glacier_transition            = bool<br/>    enable_deeparchive_transition        = bool<br/>    enable_standard_ia_transition        = bool<br/>    enable_current_object_expiration     = bool<br/>    enable_noncurrent_version_expiration = bool<br/><br/>    abort_incomplete_multipart_upload_days         = number<br/>    noncurrent_version_glacier_transition_days     = number<br/>    noncurrent_version_deeparchive_transition_days = number<br/>    noncurrent_version_expiration_days             = number<br/><br/>    standard_transition_days    = number<br/>    glacier_transition_days     = number<br/>    deeparchive_transition_days = number<br/>    expiration_days             = number<br/>  }))</pre> | `null` | no |
| <a name="input_logging"></a> [logging](#input\_logging) | Logging Object to enable and disable logging | `bool` | `false` | no |
| <a name="input_managedby"></a> [managedby](#input\_managedby) | ManagedBy, eg 'cypik'. | `string` | `"cypik"` | no |
| <a name="input_metric_configuration"></a> [metric\_configuration](#input\_metric\_configuration) | Map containing bucket metric configuration. | `any` | `[]` | no |
| <a name="input_mfa"></a> [mfa](#input\_mfa) | Optional, Required if versioning\_configuration mfa\_delete is enabled) Concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device. | `string` | `null` | no |
| <a name="input_mfa_delete"></a> [mfa\_delete](#input\_mfa\_delete) | Specifies whether MFA delete is enabled in the bucket versioning configuration. Valid values: Enabled or Disabled. | `string` | `"Disabled"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name  (e.g. `app` or `cluster`). | `string` | `""` | no |
| <a name="input_object_lock_configuration"></a> [object\_lock\_configuration](#input\_object\_lock\_configuration) | With S3 Object Lock, you can store objects using a write-once-read-many (WORM) model. Object Lock can help prevent objects from being deleted or overwritten for a fixed amount of time or indefinitely. | <pre>object({<br/>    mode  = string<br/>    days  = number<br/>    years = number<br/>  })</pre> | `null` | no |
| <a name="input_object_lock_enabled"></a> [object\_lock\_enabled](#input\_object\_lock\_enabled) | Whether S3 bucket should have an Object Lock configuration enabled. | `bool` | `false` | no |
| <a name="input_object_ownership"></a> [object\_ownership](#input\_object\_ownership) | Object ownership. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter. 'BucketOwnerEnforced': ACLs are disabled, and the bucket owner automatically owns and has full control over every object in the bucket. 'BucketOwnerPreferred': Objects uploaded to the bucket change ownership to the bucket owner if the objects are uploaded with the bucket-owner-full-control canned ACL. 'ObjectWriter': The uploading account will own the object if the object is uploaded with the bucket-owner-full-control canned ACL. | `string` | `"ObjectWriter"` | no |
| <a name="input_object_size_greater_than"></a> [object\_size\_greater\_than](#input\_object\_size\_greater\_than) | (Optional) Minimum object size for transitions. | `number` | `128000` | no |
| <a name="input_object_size_less_than"></a> [object\_size\_less\_than](#input\_object\_size\_less\_than) | (Optional) Maximum object size for transitions. | `number` | `null` | no |
| <a name="input_only_https_traffic"></a> [only\_https\_traffic](#input\_only\_https\_traffic) | This veriables use for only https traffic. | `bool` | `true` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Bucket owner's display name and ID. Conflicts with `acl` | `map(string)` | `{}` | no |
| <a name="input_owner_id"></a> [owner\_id](#input\_owner\_id) | The canonical user ID associated with the AWS account. | `string` | `""` | no |
| <a name="input_replication_configuration"></a> [replication\_configuration](#input\_replication\_configuration) | Map containing cross-region replication configuration. | `any` | `{}` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | Terraform current module repo | `string` | `"https://github.com/cypik/terraform-aws-s3"` | no |
| <a name="input_request_payer"></a> [request\_payer](#input\_request\_payer) | (Optional) Specifies who should bear the cost of Amazon S3 data transfer. Can be either BucketOwner or Requester. By default, the owner of the S3 bucket would incur the costs of any data transfer. See Requester Pays Buckets developer guide for more information. | `string` | `null` | no |
| <a name="input_restrict_public_buckets"></a> [restrict\_public\_buckets](#input\_restrict\_public\_buckets) | Whether Amazon S3 should restrict public bucket policies for this bucket. | `bool` | `true` | no |
| <a name="input_s3_name"></a> [s3\_name](#input\_s3\_name) | name of s3 bucket | `string` | `null` | no |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | The server-side encryption algorithm to use. Valid values are AES256 and aws:kms. | `string` | `"AES256"` | no |
| <a name="input_target_bucket"></a> [target\_bucket](#input\_target\_bucket) | The bucket where you want Amazon S3 to store server access logs. | `string` | `""` | no |
| <a name="input_target_grant_permission"></a> [target\_grant\_permission](#input\_target\_grant\_permission) | (Optional) Permissions granted to the grantee for the bucket. Valid values: FULL\_CONTROL, READ, WRITE. | `string` | `"FULL_CONTROL"` | no |
| <a name="input_target_prefix"></a> [target\_prefix](#input\_target\_prefix) | A prefix for all log object keys. | `string` | `""` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Define maximum timeout for creating, updating, and deleting VPC endpoint resources | `map(string)` | `{}` | no |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | Enable Versioning of S3. | `bool` | `true` | no |
| <a name="input_versioning_status"></a> [versioning\_status](#input\_versioning\_status) | Required if versioning\_configuration mfa\_delete is enabled) Concatenation of the authentication device's serial number, a space, and the value that is displayed on your authentication device. | `string` | `"Enabled"` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | n/a | `any` | `[]` | no |
| <a name="input_website"></a> [website](#input\_website) | Map containing static web-site hosting or redirect configuration. | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the s3 bucket. |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | The Domain of the s3 bucket. |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | The bucket region-specific domain name. The bucket domain name including the region name, please refer here for format. Note: The AWS CloudFront allows specifying S3 region-specific endpoint when creating S3 origin, it will prevent redirect issues from CloudFront to S3 Origin URL. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the s3 bucket. |
| <a name="output_s3_bucket_hosted_zone_id"></a> [s3\_bucket\_hosted\_zone\_id](#output\_s3\_bucket\_hosted\_zone\_id) | The Route 53 Hosted Zone ID for this bucket's region. |
| <a name="output_s3_bucket_lifecycle_configuration_rules"></a> [s3\_bucket\_lifecycle\_configuration\_rules](#output\_s3\_bucket\_lifecycle\_configuration\_rules) | The lifecycle rules of the bucket, if the bucket is configured with lifecycle rules. If not, this will be an empty string. |
| <a name="output_s3_bucket_policy"></a> [s3\_bucket\_policy](#output\_s3\_bucket\_policy) | The policy of the bucket, if the bucket is configured with a policy. If not, this will be an empty string. |
| <a name="output_s3_bucket_website_domain"></a> [s3\_bucket\_website\_domain](#output\_s3\_bucket\_website\_domain) | The domain of the website endpoint, if the bucket is configured with a website. If not, this will be an empty string. This is used to create Route 53 alias records. |
| <a name="output_s3_bucket_website_endpoint"></a> [s3\_bucket\_website\_endpoint](#output\_s3\_bucket\_website\_endpoint) | The website endpoint, if the bucket is configured with a website. If not, this will be an empty string. |
| <a name="output_tags"></a> [tags](#output\_tags) | A mapping of tags to assign to the resource. |
| <a name="output_transition_default_minimum_object_size"></a> [transition\_default\_minimum\_object\_size](#output\_transition\_default\_minimum\_object\_size) | Default minimum object size for lifecycle transitions. |
<!-- END_TF_DOCS -->