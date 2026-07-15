# Complete CodeBuild Project Example

This example creates a CodeBuild project with a customer-managed KMS key and a private, KMS-encrypted S3 artifact bucket. The functional test starts a real build that produces the configured artifact.

## Usage

```hcl
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

data "aws_region" "current" {}

module "resource_names" {
  source  = "terraform.registry.launch.nttdata.com/module_library/resource_name/launch"
  version = "~> 2.0"

  for_each = var.resource_names_map

  logical_product_family  = var.logical_product_family
  logical_product_service = var.logical_product_service
  class_env               = var.class_env
  instance_env            = var.instance_env
  instance_resource       = var.instance_resource
  cloud_resource_type     = each.value.name
  maximum_length          = each.value.max_length
  region                  = join("", split("-", data.aws_region.current.region))
}

resource "aws_kms_key" "artifacts" {
  description             = "Encryption key for the CodeBuild example output artifacts."
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = module.resource_names["artifacts"].minimal_random_suffix
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.artifacts.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name = module.resource_names["role"].standard

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "codebuild" {
  name = "codebuild-example-artifacts"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = aws_kms_key.artifacts.arn
      }
    ]
  })
}

module "project" {
  source = "../.."

  name         = coalesce(var.name, module.resource_names["project"].standard)
  service_role = coalesce(var.service_role, aws_iam_role.codebuild.arn)
  artifacts = var.artifacts == null ? {
    type                   = "S3"
    artifact_identifier    = null
    bucket_owner_access    = null
    encryption_disabled    = null
    location               = aws_s3_bucket.artifacts.id
    name                   = "output.zip"
    namespace_type         = "BUILD_ID"
    override_artifact_name = null
    packaging              = "ZIP"
    path                   = null
  } : var.artifacts
  environment = var.environment == null ? {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    certificate                 = null
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    docker_server               = null
    environment_variables       = []
    fleet                       = null
    registry_credential         = null
  } : var.environment
  primary_source = var.primary_source == null ? {
    type                  = "NO_SOURCE"
    buildspec             = <<-EOT
    version: 0.2
    phases:
      build:
        commands:
          - echo "CodeBuild primitive module functional test" > output.txt
    artifacts:
      files:
        - output.txt
    EOT
    auth                  = null
    build_status_config   = null
    git_clone_depth       = null
    git_submodules_config = null
    insecure_ssl          = null
    location              = null
    report_build_status   = null
  } : var.primary_source
  auto_retry_limit          = var.auto_retry_limit
  badge_enabled             = var.badge_enabled
  build_batch_config        = var.build_batch_config
  build_timeout             = var.build_timeout
  cache                     = var.cache
  concurrent_build_limit    = var.concurrent_build_limit
  description               = var.description
  encryption_key            = coalesce(var.encryption_key, aws_kms_key.artifacts.arn)
  file_system_locations     = var.file_system_locations
  logs_config               = var.logs_config
  project_visibility        = var.project_visibility
  queued_timeout            = var.queued_timeout
  region                    = var.region
  resource_access_role      = var.resource_access_role
  secondary_artifacts       = var.secondary_artifacts
  secondary_source_versions = var.secondary_source_versions
  secondary_sources         = var.secondary_sources
  source_version            = var.source_version
  tags                      = var.tags
  vpc_config                = var.vpc_config

  depends_on = [
    aws_iam_role_policy.codebuild,
    aws_s3_bucket_public_access_block.artifacts,
    aws_s3_bucket_server_side_encryption_configuration.artifacts
  ]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.16, < 7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_project"></a> [project](#module\_project) | ../.. | n/a |
| <a name="module_resource_names"></a> [resource\_names](#module\_resource\_names) | terraform.registry.launch.nttdata.com/module_library/resource_name/launch | ~> 2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_key.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_artifacts"></a> [artifacts](#input\_artifacts) | Optional override for the secure S3 artifact configuration used by the example. | <pre>object({<br/>    type                   = string<br/>    artifact_identifier    = optional(string)<br/>    bucket_owner_access    = optional(string)<br/>    encryption_disabled    = optional(bool)<br/>    location               = optional(string)<br/>    name                   = optional(string)<br/>    namespace_type         = optional(string)<br/>    override_artifact_name = optional(bool)<br/>    packaging              = optional(string)<br/>    path                   = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_auto_retry_limit"></a> [auto\_retry\_limit](#input\_auto\_retry\_limit) | Maximum number of automatic build retries. | `number` | `null` | no |
| <a name="input_badge_enabled"></a> [badge\_enabled](#input\_badge\_enabled) | Whether build badges are enabled. | `bool` | `false` | no |
| <a name="input_build_batch_config"></a> [build\_batch\_config](#input\_build\_batch\_config) | Optional batch build configuration. | <pre>object({<br/>    service_role      = string<br/>    combine_artifacts = optional(bool)<br/>    timeout_in_mins   = optional(number)<br/>    restrictions = optional(object({<br/>      compute_types_allowed  = optional(list(string))<br/>      maximum_builds_allowed = optional(number)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_build_timeout"></a> [build\_timeout](#input\_build\_timeout) | Maximum build duration in minutes. | `number` | `null` | no |
| <a name="input_cache"></a> [cache](#input\_cache) | Optional build cache configuration. | <pre>object({<br/>    type            = string<br/>    cache_namespace = optional(string)<br/>    location        = optional(string)<br/>    modes           = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_class_env"></a> [class\_env](#input\_class\_env) | Environment class for generated resource names. | `string` | n/a | yes |
| <a name="input_concurrent_build_limit"></a> [concurrent\_build\_limit](#input\_concurrent\_build\_limit) | Maximum number of concurrent builds. | `number` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the CodeBuild project. | `string` | `null` | no |
| <a name="input_encryption_key"></a> [encryption\_key](#input\_encryption\_key) | Optional override for the example customer-managed artifact encryption key ARN. The external key policy and IAM policy must grant the example CodeBuild role KMS permissions. | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Optional override for the CodeBuild environment configuration. | <pre>object({<br/>    compute_type                = string<br/>    image                       = string<br/>    type                        = string<br/>    certificate                 = optional(string)<br/>    image_pull_credentials_type = optional(string)<br/>    privileged_mode             = optional(bool)<br/>    docker_server = optional(object({<br/>      compute_type       = string<br/>      security_group_ids = optional(list(string))<br/>    }))<br/>    environment_variables = optional(list(object({<br/>      name  = string<br/>      value = string<br/>      type  = optional(string)<br/>    })), [])<br/>    fleet = optional(object({<br/>      fleet_arn = string<br/>    }))<br/>    registry_credential = optional(object({<br/>      credential          = string<br/>      credential_provider = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_file_system_locations"></a> [file\_system\_locations](#input\_file\_system\_locations) | EFS file-system locations available to builds. | <pre>set(object({<br/>    identifier    = string<br/>    location      = string<br/>    mount_options = optional(string)<br/>    mount_point   = string<br/>    type          = string<br/>  }))</pre> | `[]` | no |
| <a name="input_instance_env"></a> [instance\_env](#input\_instance\_env) | Environment instance number for generated resource names. | `number` | n/a | yes |
| <a name="input_instance_resource"></a> [instance\_resource](#input\_instance\_resource) | Resource instance number for generated resource names. | `number` | n/a | yes |
| <a name="input_logical_product_family"></a> [logical\_product\_family](#input\_logical\_product\_family) | Logical product family for generated resource names. | `string` | n/a | yes |
| <a name="input_logical_product_service"></a> [logical\_product\_service](#input\_logical\_product\_service) | Logical product service for generated resource names. | `string` | n/a | yes |
| <a name="input_logs_config"></a> [logs\_config](#input\_logs\_config) | Optional CloudWatch Logs and S3 logs configuration. | <pre>object({<br/>    cloudwatch_logs = optional(object({<br/>      group_name  = optional(string)<br/>      status      = optional(string)<br/>      stream_name = optional(string)<br/>    }))<br/>    s3_logs = optional(object({<br/>      bucket_owner_access = optional(string)<br/>      encryption_disabled = optional(bool)<br/>      location            = optional(string)<br/>      status              = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Optional override for the generated CodeBuild project name. | `string` | `null` | no |
| <a name="input_primary_source"></a> [primary\_source](#input\_primary\_source) | Optional override for the no-source inline-buildspec configuration used by the example. | <pre>object({<br/>    type                = string<br/>    buildspec           = optional(string)<br/>    git_clone_depth     = optional(number)<br/>    insecure_ssl        = optional(bool)<br/>    location            = optional(string)<br/>    report_build_status = optional(bool)<br/>    auth = optional(object({<br/>      resource = string<br/>      type     = string<br/>    }))<br/>    build_status_config = optional(object({<br/>      context    = optional(string)<br/>      target_url = optional(string)<br/>    }))<br/>    git_submodules_config = optional(object({<br/>      fetch_submodules = bool<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_project_visibility"></a> [project\_visibility](#input\_project\_visibility) | Visibility of the CodeBuild project. | `string` | `"PRIVATE"` | no |
| <a name="input_queued_timeout"></a> [queued\_timeout](#input\_queued\_timeout) | Maximum queue duration in minutes. | `number` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Optional AWS provider v6 per-resource region override. | `string` | `null` | no |
| <a name="input_resource_access_role"></a> [resource\_access\_role](#input\_resource\_access\_role) | Optional public-project resource access role ARN. | `string` | `null` | no |
| <a name="input_resource_names_map"></a> [resource\_names\_map](#input\_resource\_names\_map) | Resource name configuration keyed by resource role. | <pre>map(object({<br/>    name       = string<br/>    max_length = number<br/>  }))</pre> | n/a | yes |
| <a name="input_secondary_artifacts"></a> [secondary\_artifacts](#input\_secondary\_artifacts) | Secondary artifact configurations. | <pre>set(object({<br/>    artifact_identifier    = string<br/>    type                   = string<br/>    bucket_owner_access    = optional(string)<br/>    encryption_disabled    = optional(bool)<br/>    location               = optional(string)<br/>    name                   = optional(string)<br/>    namespace_type         = optional(string)<br/>    override_artifact_name = optional(bool)<br/>    packaging              = optional(string)<br/>    path                   = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_secondary_source_versions"></a> [secondary\_source\_versions](#input\_secondary\_source\_versions) | Versions for secondary sources. | <pre>set(object({<br/>    source_identifier = string<br/>    source_version    = string<br/>  }))</pre> | `[]` | no |
| <a name="input_secondary_sources"></a> [secondary\_sources](#input\_secondary\_sources) | Secondary source configurations. | <pre>set(object({<br/>    source_identifier   = string<br/>    type                = string<br/>    buildspec           = optional(string)<br/>    git_clone_depth     = optional(number)<br/>    insecure_ssl        = optional(bool)<br/>    location            = optional(string)<br/>    report_build_status = optional(bool)<br/>    auth = optional(object({<br/>      resource = string<br/>      type     = string<br/>    }))<br/>    build_status_config = optional(object({<br/>      context    = optional(string)<br/>      target_url = optional(string)<br/>    }))<br/>    git_submodules_config = optional(object({<br/>      fetch_submodules = bool<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_service_role"></a> [service\_role](#input\_service\_role) | Optional override for the example CodeBuild service role ARN. | `string` | `null` | no |
| <a name="input_source_version"></a> [source\_version](#input\_source\_version) | Optional version of the primary source to build. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all example resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | Optional VPC configuration for the CodeBuild project. | <pre>object({<br/>    security_group_ids = set(string)<br/>    subnets            = set(string)<br/>    vpc_id             = string<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The CodeBuild project ARN. |
| <a name="output_expected_artifact_bucket"></a> [expected\_artifact\_bucket](#output\_expected\_artifact\_bucket) | The S3 bucket configured for the project artifacts. |
| <a name="output_expected_badge_enabled"></a> [expected\_badge\_enabled](#output\_expected\_badge\_enabled) | Whether the example expects a project build badge. |
| <a name="output_expected_build_timeout"></a> [expected\_build\_timeout](#output\_expected\_build\_timeout) | The expected build timeout in minutes for the example. |
| <a name="output_expected_cache_type"></a> [expected\_cache\_type](#output\_expected\_cache\_type) | The cache type expected on the project, when configured. |
| <a name="output_expected_description"></a> [expected\_description](#output\_expected\_description) | The description expected on the project. |
| <a name="output_expected_encryption_key_arn"></a> [expected\_encryption\_key\_arn](#output\_expected\_encryption\_key\_arn) | The customer-managed KMS key expected to encrypt the project output artifacts. |
| <a name="output_expected_environment_compute_type"></a> [expected\_environment\_compute\_type](#output\_expected\_environment\_compute\_type) | The expected CodeBuild compute type for the example. |
| <a name="output_expected_environment_type"></a> [expected\_environment\_type](#output\_expected\_environment\_type) | The expected CodeBuild environment type for the example. |
| <a name="output_expected_environment_variables"></a> [expected\_environment\_variables](#output\_expected\_environment\_variables) | The environment variables expected on the project. |
| <a name="output_expected_source_type"></a> [expected\_source\_type](#output\_expected\_source\_type) | The expected primary source type for the example. |
| <a name="output_expected_tags"></a> [expected\_tags](#output\_expected\_tags) | The tags expected on the project. |
| <a name="output_id"></a> [id](#output\_id) | The CodeBuild project ID. |
| <a name="output_name"></a> [name](#output\_name) | The CodeBuild project name. |
| <a name="output_region"></a> [region](#output\_region) | The region where the CodeBuild project is managed. |
<!-- END_TF_DOCS -->
