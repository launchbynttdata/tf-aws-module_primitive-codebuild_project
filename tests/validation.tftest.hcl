# Validates module input contracts without calling AWS.
mock_provider "aws" {}

variables {
  name         = "codebuild-project-test"
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

run "all_dynamic_blocks_plan" {
  command = plan

  variables {
    build_batch_config = {
      service_role = "arn:aws:iam::123456789012:role/codebuild-batch-test"
      restrictions = {
        compute_types_allowed  = ["BUILD_GENERAL1_SMALL"]
        maximum_builds_allowed = 1
      }
    }
    cache = {
      type  = "LOCAL"
      modes = ["LOCAL_CUSTOM_CACHE"]
    }
    environment = {
      compute_type = "BUILD_GENERAL1_SMALL"
      image        = "aws/codebuild/standard:7.0"
      type         = "LINUX_CONTAINER"
      docker_server = {
        compute_type = "BUILD_GENERAL1_SMALL"
      }
      environment_variables = [{
        name  = "TEST_VALUE"
        value = "test"
        type  = "PLAINTEXT"
      }]
    }
    file_system_locations = [{
      identifier  = "test-efs"
      location    = "fs-12345678.efs.us-east-1.amazonaws.com:/"
      mount_point = "/mnt/test"
      type        = "EFS"
    }]
    logs_config = {
      cloudwatch_logs = {
        group_name  = "/aws/codebuild/test"
        status      = "ENABLED"
        stream_name = "test"
      }
      s3_logs = {
        location = "codebuild-project-test-artifacts/logs"
        status   = "ENABLED"
      }
    }
    secondary_artifacts = [{
      artifact_identifier = "secondary"
      type                = "S3"
      location            = "codebuild-project-test-artifacts"
    }]
    secondary_sources = [{
      source_identifier = "secondary"
      type              = "NO_SOURCE"
    }]
    secondary_source_versions = [{
      source_identifier = "secondary"
      source_version    = "main"
    }]
    vpc_config = {
      security_group_ids = ["sg-12345678"]
      subnets            = ["subnet-12345678"]
      vpc_id             = "vpc-12345678"
    }
  }
}

run "fleet_and_source_sub_blocks_plan" {
  command = plan

  variables {
    environment = {
      compute_type = "BUILD_GENERAL1_SMALL"
      image        = "aws/codebuild/standard:7.0"
      type         = "LINUX_CONTAINER"
      fleet = {
        fleet_arn = "arn:aws:codebuild:us-east-2:123456789012:fleet/test"
      }
    }
    primary_source = {
      type                = "GITHUB"
      location            = "https://github.com/example/repo.git"
      report_build_status = true
      build_status_config = {
        context    = "CodeBuild"
        target_url = "https://example.com/build"
      }
      git_submodules_config = {
        fetch_submodules = true
      }
    }
    secondary_sources = [{
      source_identifier   = "secondary"
      type                = "GITHUB"
      location            = "https://github.com/example/secondary.git"
      report_build_status = true
      build_status_config = {
        context    = "CodeBuild secondary"
        target_url = "https://example.com/secondary-build"
      }
      git_submodules_config = {
        fetch_submodules = true
      }
    }]
  }
}

run "fleet_without_arn_rejected" {
  command = plan

  variables {
    environment = {
      compute_type = "BUILD_GENERAL1_SMALL"
      image        = "aws/codebuild/standard:7.0"
      type         = "LINUX_CONTAINER"
      fleet        = {}
    }
  }

  expect_failures = [var.environment]
}

run "primary_build_status_config_unsupported_source_rejected" {
  command = plan

  variables {
    primary_source = {
      type     = "S3"
      location = "codebuild-project-test-artifacts/source.zip"
      build_status_config = {
        context = "CodeBuild"
      }
    }
  }

  expect_failures = [var.primary_source]
}

run "secondary_build_status_config_unsupported_source_rejected" {
  command = plan

  variables {
    secondary_sources = [{
      source_identifier = "secondary"
      type              = "S3"
      location          = "codebuild-project-test-artifacts/source.zip"
      build_status_config = {
        context = "CodeBuild secondary"
      }
    }]
  }

  expect_failures = [var.secondary_sources]
}

run "git_submodules_without_fetch_flag_rejected" {
  command = plan

  variables {
    primary_source = {
      type                  = "GITHUB"
      location              = "https://github.com/example/repo.git"
      git_submodules_config = {}
    }
  }

  expect_failures = [var.primary_source]
}

run "non_s3_artifact_override_plan" {
  command = plan

  variables {
    artifacts = {
      type = "NO_ARTIFACTS"
    }
  }
}

run "disabled_cloudwatch_logs_rejected" {
  command = plan

  variables {
    logs_config = {
      cloudwatch_logs = {
        status     = "DISABLED"
        group_name = "/aws/codebuild/test"
      }
    }
  }

  expect_failures = [var.logs_config]
}

run "unknown_secondary_source_version_rejected" {
  command = plan

  variables {
    secondary_source_versions = [{
      source_identifier = "missing"
      source_version    = "main"
    }]
  }

  expect_failures = [aws_codebuild_project.project]
}

run "source_cache_with_no_source_rejected" {
  command = plan

  variables {
    cache = {
      type  = "LOCAL"
      modes = ["LOCAL_SOURCE_CACHE"]
    }
  }

  expect_failures = [aws_codebuild_project.project]
}

run "badges_with_no_source_rejected" {
  command = plan

  variables {
    badge_enabled = true
  }

  expect_failures = [aws_codebuild_project.project]
}
