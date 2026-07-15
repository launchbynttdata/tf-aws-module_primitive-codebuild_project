# Plan-only tests for the module's input validation rules. The AWS provider is
# mocked, so no credentials or API calls are required. Each *_rejected run is
# crafted so that exactly one validation rule can trip, ensuring an expected
# failure cannot pass for the wrong reason.
mock_provider "aws" {}

variables {
  name         = "codebuild-project-validation"
  service_role = "arn:aws:iam::123456789012:role/codebuild-test"

  artifacts = {
    type     = "S3"
    location = "codebuild-project-test-artifacts"
  }

  environment = {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  primary_source = {
    type      = "NO_SOURCE"
    buildspec = "version: 0.2"
  }
}

# -----------------------------------------------------------------------------
# Positive boundary cases
# -----------------------------------------------------------------------------

run "lower_boundary_values_accepted" {
  command = plan

  variables {
    auto_retry_limit       = 0
    build_timeout          = 5
    queued_timeout         = 5
    concurrent_build_limit = 1
    description            = join("", [for i in range(255) : "a"])
    encryption_key         = "alias/test"

    primary_source = {
      type            = "GITHUB"
      location        = "https://github.com/example/repo.git"
      git_clone_depth = 0
      auth = {
        resource = "arn:aws:codeconnections:us-east-2:123456789012:connection/example"
        type     = "CODECONNECTIONS"
      }
    }
  }
}

run "upper_boundary_values_accepted" {
  command = plan

  variables {
    build_timeout  = 2160
    queued_timeout = 480

    environment = {
      compute_type                = "BUILD_GENERAL1_SMALL"
      image                       = "aws/codebuild/standard:7.0"
      type                        = "LINUX_CONTAINER"
      image_pull_credentials_type = "SERVICE_ROLE"
      registry_credential = {
        credential          = "arn:aws:secretsmanager:us-east-2:123456789012:secret:registry"
        credential_provider = "SECRETS_MANAGER"
      }
    }

    tags = {
      (join("", [for i in range(128) : "k"])) = join("", [for i in range(256) : "v"])
    }
  }
}

run "codepipeline_source_and_artifacts_accepted" {
  command = plan

  variables {
    artifacts = {
      type = "CODEPIPELINE"
    }

    primary_source = {
      type = "CODEPIPELINE"
    }
  }
}

# -----------------------------------------------------------------------------
# name / service_role
# -----------------------------------------------------------------------------

run "name_invalid_format_rejected" {
  command = plan

  variables {
    name = "_starts-with-underscore"
  }

  expect_failures = [var.name]
}

run "service_role_empty_rejected" {
  command = plan

  variables {
    service_role = ""
  }

  expect_failures = [var.service_role]
}

# -----------------------------------------------------------------------------
# artifacts
# -----------------------------------------------------------------------------

run "artifacts_type_invalid_rejected" {
  command = plan

  variables {
    artifacts = {
      type = "LOCAL"
    }
  }

  expect_failures = [var.artifacts]
}

run "artifacts_s3_missing_location_rejected" {
  command = plan

  variables {
    artifacts = {
      type = "S3"
    }
  }

  expect_failures = [var.artifacts]
}

run "artifacts_encryption_disabled_non_s3_rejected" {
  command = plan

  variables {
    artifacts = {
      type                = "NO_ARTIFACTS"
      encryption_disabled = true
    }
  }

  expect_failures = [var.artifacts]
}

run "artifacts_bucket_owner_access_invalid_rejected" {
  command = plan

  variables {
    artifacts = {
      type                = "S3"
      location            = "codebuild-project-test-artifacts"
      bucket_owner_access = "WRITE"
    }
  }

  expect_failures = [var.artifacts]
}

run "artifacts_namespace_type_invalid_rejected" {
  command = plan

  variables {
    artifacts = {
      type           = "S3"
      location       = "codebuild-project-test-artifacts"
      namespace_type = "DATE"
    }
  }

  expect_failures = [var.artifacts]
}

run "artifacts_packaging_invalid_rejected" {
  command = plan

  variables {
    artifacts = {
      type      = "S3"
      location  = "codebuild-project-test-artifacts"
      packaging = "TAR"
    }
  }

  expect_failures = [var.artifacts]
}

# -----------------------------------------------------------------------------
# environment
# -----------------------------------------------------------------------------

run "environment_compute_type_invalid_rejected" {
  command = plan

  variables {
    environment = {
      compute_type = "BUILD_GENERAL1_10XLARGE"
      image        = "aws/codebuild/standard:7.0"
      type         = "LINUX_CONTAINER"
    }
  }

  expect_failures = [var.environment]
}

run "environment_type_invalid_rejected" {
  command = plan

  variables {
    environment = {
      compute_type = "BUILD_GENERAL1_SMALL"
      image        = "aws/codebuild/standard:7.0"
      type         = "SOLARIS_CONTAINER"
    }
  }

  expect_failures = [var.environment]
}

run "environment_image_pull_credentials_type_invalid_rejected" {
  command = plan

  variables {
    environment = {
      compute_type                = "BUILD_GENERAL1_SMALL"
      image                       = "aws/codebuild/standard:7.0"
      type                        = "LINUX_CONTAINER"
      image_pull_credentials_type = "IAM"
    }
  }

  expect_failures = [var.environment]
}

run "environment_registry_credential_without_service_role_rejected" {
  command = plan

  variables {
    environment = {
      compute_type = "BUILD_GENERAL1_SMALL"
      image        = "aws/codebuild/standard:7.0"
      type         = "LINUX_CONTAINER"
      registry_credential = {
        credential          = "arn:aws:secretsmanager:us-east-2:123456789012:secret:registry"
        credential_provider = "SECRETS_MANAGER"
      }
    }
  }

  expect_failures = [var.environment]
}

run "environment_variable_type_invalid_rejected" {
  command = plan

  variables {
    environment = {
      compute_type = "BUILD_GENERAL1_SMALL"
      image        = "aws/codebuild/standard:7.0"
      type         = "LINUX_CONTAINER"
      environment_variables = [{
        name  = "TEST_VALUE"
        value = "test"
        type  = "SSM"
      }]
    }
  }

  expect_failures = [var.environment]
}

# -----------------------------------------------------------------------------
# primary_source
# -----------------------------------------------------------------------------

run "primary_source_type_invalid_rejected" {
  command = plan

  variables {
    primary_source = {
      type     = "SVN"
      location = "https://svn.example.com/repo"
    }
  }

  expect_failures = [var.primary_source]
}

run "primary_source_missing_location_rejected" {
  command = plan

  variables {
    primary_source = {
      type = "GITHUB"
    }
  }

  expect_failures = [var.primary_source]
}

run "primary_source_no_source_with_location_rejected" {
  command = plan

  variables {
    primary_source = {
      type      = "NO_SOURCE"
      buildspec = "version: 0.2"
      location  = "https://github.com/example/repo.git"
    }
  }

  expect_failures = [var.primary_source]
}

run "primary_source_negative_git_clone_depth_rejected" {
  command = plan

  variables {
    primary_source = {
      type            = "GITHUB"
      location        = "https://github.com/example/repo.git"
      git_clone_depth = -1
    }
  }

  expect_failures = [var.primary_source]
}

run "primary_source_auth_non_repository_rejected" {
  command = plan

  variables {
    primary_source = {
      type     = "S3"
      location = "codebuild-project-test-artifacts/source.zip"
      auth = {
        resource = "arn:aws:codeconnections:us-east-2:123456789012:connection/example"
        type     = "CODECONNECTIONS"
      }
    }
  }

  expect_failures = [var.primary_source]
}

# -----------------------------------------------------------------------------
# Scalar limits
# -----------------------------------------------------------------------------

run "auto_retry_limit_negative_rejected" {
  command = plan

  variables {
    auto_retry_limit = -1
  }

  expect_failures = [var.auto_retry_limit]
}

run "build_timeout_below_minimum_rejected" {
  command = plan

  variables {
    build_timeout = 4
  }

  expect_failures = [var.build_timeout]
}

run "build_timeout_above_maximum_rejected" {
  command = plan

  variables {
    build_timeout = 2161
  }

  expect_failures = [var.build_timeout]
}

run "queued_timeout_below_minimum_rejected" {
  command = plan

  variables {
    queued_timeout = 4
  }

  expect_failures = [var.queued_timeout]
}

run "queued_timeout_above_maximum_rejected" {
  command = plan

  variables {
    queued_timeout = 481
  }

  expect_failures = [var.queued_timeout]
}

run "concurrent_build_limit_invalid_rejected" {
  command = plan

  variables {
    concurrent_build_limit = 0
  }

  expect_failures = [var.concurrent_build_limit]
}

run "description_too_long_rejected" {
  command = plan

  variables {
    description = join("", [for i in range(256) : "a"])
  }

  expect_failures = [var.description]
}

run "encryption_key_empty_rejected" {
  command = plan

  variables {
    encryption_key = ""
  }

  expect_failures = [var.encryption_key]
}

run "project_visibility_invalid_rejected" {
  command = plan

  variables {
    project_visibility = "INTERNAL"
  }

  expect_failures = [var.project_visibility]
}

# -----------------------------------------------------------------------------
# build_batch_config / cache
# -----------------------------------------------------------------------------

run "build_batch_config_maximum_builds_invalid_rejected" {
  command = plan

  variables {
    build_batch_config = {
      service_role = "arn:aws:iam::123456789012:role/codebuild-batch-test"
      restrictions = {
        maximum_builds_allowed = 0
      }
    }
  }

  expect_failures = [var.build_batch_config]
}

run "cache_type_invalid_rejected" {
  command = plan

  variables {
    cache = {
      type = "REDIS"
    }
  }

  expect_failures = [var.cache]
}

run "cache_s3_missing_location_rejected" {
  command = plan

  variables {
    cache = {
      type = "S3"
    }
  }

  expect_failures = [var.cache]
}

run "cache_no_cache_with_location_rejected" {
  command = plan

  variables {
    cache = {
      type     = "NO_CACHE"
      location = "codebuild-project-test-artifacts/cache"
    }
  }

  expect_failures = [var.cache]
}

run "cache_mode_invalid_rejected" {
  command = plan

  variables {
    cache = {
      type  = "LOCAL"
      modes = ["LOCAL_TMP_CACHE"]
    }
  }

  expect_failures = [var.cache]
}

# -----------------------------------------------------------------------------
# file_system_locations / logs_config / vpc_config
# -----------------------------------------------------------------------------

run "file_system_location_type_invalid_rejected" {
  command = plan

  variables {
    file_system_locations = [{
      identifier  = "test-efs"
      location    = "fs-12345678.efs.us-east-1.amazonaws.com:/"
      mount_point = "/mnt/test"
      type        = "FSX"
    }]
  }

  expect_failures = [var.file_system_locations]
}

run "logs_cloudwatch_status_invalid_rejected" {
  command = plan

  variables {
    logs_config = {
      cloudwatch_logs = {
        status = "PAUSED"
      }
    }
  }

  expect_failures = [var.logs_config]
}

run "logs_s3_status_invalid_rejected" {
  command = plan

  variables {
    logs_config = {
      s3_logs = {
        status = "PAUSED"
      }
    }
  }

  expect_failures = [var.logs_config]
}

run "logs_s3_bucket_owner_access_invalid_rejected" {
  command = plan

  variables {
    logs_config = {
      s3_logs = {
        status              = "ENABLED"
        location            = "codebuild-project-test-artifacts/logs"
        bucket_owner_access = "WRITE"
      }
    }
  }

  expect_failures = [var.logs_config]
}

run "logs_s3_disabled_with_location_rejected" {
  command = plan

  variables {
    logs_config = {
      s3_logs = {
        status   = "DISABLED"
        location = "codebuild-project-test-artifacts/logs"
      }
    }
  }

  expect_failures = [var.logs_config]
}

run "logs_s3_disabled_with_related_fields_rejected" {
  command = plan

  variables {
    logs_config = {
      s3_logs = {
        status              = "DISABLED"
        bucket_owner_access = "FULL"
        encryption_disabled = true
      }
    }
  }

  expect_failures = [var.logs_config]
}

run "vpc_config_missing_security_groups_rejected" {
  command = plan

  variables {
    vpc_config = {
      security_group_ids = []
      subnets            = ["subnet-12345678"]
      vpc_id             = "vpc-12345678"
    }
  }

  expect_failures = [var.vpc_config]
}

# -----------------------------------------------------------------------------
# Secondary sources, artifacts, and versions
# -----------------------------------------------------------------------------

run "secondary_artifacts_s3_missing_location_rejected" {
  command = plan

  variables {
    secondary_artifacts = [{
      artifact_identifier = "secondary"
      type                = "S3"
    }]
  }

  expect_failures = [var.secondary_artifacts]
}

run "secondary_sources_no_source_with_location_rejected" {
  command = plan

  variables {
    secondary_sources = [{
      source_identifier = "secondary"
      type              = "NO_SOURCE"
      location          = "https://github.com/example/repo.git"
    }]
  }

  expect_failures = [var.secondary_sources]
}

run "secondary_source_versions_too_many_rejected" {
  command = plan

  variables {
    secondary_source_versions = [
      { source_identifier = "s01", source_version = "main" },
      { source_identifier = "s02", source_version = "main" },
      { source_identifier = "s03", source_version = "main" },
      { source_identifier = "s04", source_version = "main" },
      { source_identifier = "s05", source_version = "main" },
      { source_identifier = "s06", source_version = "main" },
      { source_identifier = "s07", source_version = "main" },
      { source_identifier = "s08", source_version = "main" },
      { source_identifier = "s09", source_version = "main" },
      { source_identifier = "s10", source_version = "main" },
      { source_identifier = "s11", source_version = "main" },
      { source_identifier = "s12", source_version = "main" },
      { source_identifier = "s13", source_version = "main" },
    ]
  }

  expect_failures = [var.secondary_source_versions]
}

# -----------------------------------------------------------------------------
# tags
# -----------------------------------------------------------------------------

run "tags_key_too_long_rejected" {
  command = plan

  variables {
    tags = {
      (join("", [for i in range(129) : "k"])) = "value"
    }
  }

  expect_failures = [var.tags]
}

run "tags_value_too_long_rejected" {
  command = plan

  variables {
    tags = {
      purpose = join("", [for i in range(257) : "v"])
    }
  }

  expect_failures = [var.tags]
}
