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
