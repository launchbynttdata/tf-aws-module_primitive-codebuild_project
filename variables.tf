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

# -----------------------------------------------------------------------------
# Required project configuration
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the CodeBuild project. It must be 2 to 150 characters, start with an alphanumeric character, and then contain only alphanumeric characters, hyphens, or underscores."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]{1,149}$", var.name))
    error_message = "name must be 2 to 150 characters, start with an alphanumeric character, and contain only alphanumeric characters, hyphens, or underscores."
  }
}

variable "service_role" {
  description = "ARN of the IAM service role that allows CodeBuild to interact with dependent AWS services."
  type        = string

  validation {
    condition     = length(var.service_role) >= 1
    error_message = "service_role must not be empty."
  }
}

variable "artifacts" {
  description = "Primary build output artifact configuration. location is required when type is S3."
  type = object({
    type                   = string
    artifact_identifier    = optional(string)
    bucket_owner_access    = optional(string)
    encryption_disabled    = optional(bool)
    location               = optional(string)
    name                   = optional(string)
    namespace_type         = optional(string)
    override_artifact_name = optional(bool)
    packaging              = optional(string)
    path                   = optional(string)
  })

  validation {
    condition     = contains(["CODEPIPELINE", "NO_ARTIFACTS", "S3"], var.artifacts.type)
    error_message = "artifacts.type must be CODEPIPELINE, NO_ARTIFACTS, or S3."
  }

  validation {
    condition     = var.artifacts.type != "S3" ? true : try(var.artifacts.location, null) != null
    error_message = "artifacts.location is required when artifacts.type is S3."
  }

  validation {
    condition     = try(var.artifacts.encryption_disabled, null) == null || var.artifacts.type == "S3"
    error_message = "artifacts.encryption_disabled is supported only when artifacts.type is S3."
  }

  validation {
    condition     = try(var.artifacts.bucket_owner_access, null) == null ? true : contains(["FULL", "NONE", "READ_ONLY"], var.artifacts.bucket_owner_access)
    error_message = "artifacts.bucket_owner_access must be FULL, NONE, or READ_ONLY when specified."
  }

  validation {
    condition     = try(var.artifacts.namespace_type, null) == null ? true : contains(["BUILD_ID", "NONE"], var.artifacts.namespace_type)
    error_message = "artifacts.namespace_type must be BUILD_ID or NONE when specified."
  }

  validation {
    condition     = try(var.artifacts.packaging, null) == null ? true : contains(["NONE", "ZIP"], var.artifacts.packaging)
    error_message = "artifacts.packaging must be NONE or ZIP when specified."
  }
}

variable "environment" {
  description = "Build environment configuration. registry_credential requires image_pull_credentials_type to be SERVICE_ROLE. docker_server, fleet, and registry_credential are optional single blocks."
  type = object({
    compute_type                = string
    image                       = string
    type                        = string
    certificate                 = optional(string)
    image_pull_credentials_type = optional(string)
    privileged_mode             = optional(bool)
    docker_server = optional(object({
      compute_type       = string
      security_group_ids = optional(list(string))
    }))
    environment_variables = optional(list(object({
      name  = string
      value = string
      type  = optional(string)
    })), [])
    fleet = optional(object({
      fleet_arn = string
    }))
    registry_credential = optional(object({
      credential          = string
      credential_provider = string
    }))
  })

  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL", "BUILD_GENERAL1_MEDIUM", "BUILD_GENERAL1_LARGE",
      "BUILD_GENERAL1_XLARGE", "BUILD_GENERAL1_2XLARGE", "BUILD_LAMBDA_1GB", "BUILD_LAMBDA_2GB",
      "BUILD_LAMBDA_4GB", "BUILD_LAMBDA_8GB", "BUILD_LAMBDA_10GB"
    ], var.environment.compute_type)
    error_message = "environment.compute_type must be a supported CodeBuild compute type."
  }

  validation {
    condition = contains([
      "ARM_CONTAINER", "ARM_EC2", "ARM_LAMBDA_CONTAINER", "LINUX_CONTAINER", "LINUX_EC2",
      "LINUX_GPU_CONTAINER", "LINUX_LAMBDA_CONTAINER", "MAC_ARM", "WINDOWS_CONTAINER", "WINDOWS_EC2",
      "WINDOWS_SERVER_2019_CONTAINER", "WINDOWS_SERVER_2022_CONTAINER"
    ], var.environment.type)
    error_message = "environment.type must be a supported CodeBuild environment type."
  }

  validation {
    condition     = try(var.environment.image_pull_credentials_type, null) == null ? true : contains(["CODEBUILD", "SERVICE_ROLE"], var.environment.image_pull_credentials_type)
    error_message = "environment.image_pull_credentials_type must be CODEBUILD or SERVICE_ROLE when specified."
  }

  validation {
    condition     = try(var.environment.registry_credential, null) == null ? true : try(var.environment.image_pull_credentials_type, null) == "SERVICE_ROLE"
    error_message = "environment.image_pull_credentials_type must be SERVICE_ROLE when registry_credential is configured."
  }

  validation {
    condition = alltrue([
      for environment_variable in var.environment.environment_variables :
      try(environment_variable.type, null) == null || contains(["PARAMETER_STORE", "PLAINTEXT", "SECRETS_MANAGER"], environment_variable.type)
    ])
    error_message = "environment.environment_variables[*].type must be PARAMETER_STORE, PLAINTEXT, or SECRETS_MANAGER when specified."
  }
}

variable "primary_source" {
  description = "Primary build input source. location must be omitted for CODEPIPELINE and NO_SOURCE, and is required for every other source type. auth and git_submodules_config are optional single blocks. build_status_config is supported only for GITHUB, GITHUB_ENTERPRISE, and BITBUCKET sources."
  type = object({
    type                = string
    buildspec           = optional(string)
    git_clone_depth     = optional(number)
    insecure_ssl        = optional(bool)
    location            = optional(string)
    report_build_status = optional(bool)
    auth = optional(object({
      resource = string
      type     = string
    }))
    build_status_config = optional(object({
      context    = optional(string)
      target_url = optional(string)
    }))
    git_submodules_config = optional(object({
      fetch_submodules = bool
    }))
  })

  validation {
    condition     = contains(["BITBUCKET", "CODECOMMIT", "CODEPIPELINE", "GITHUB", "GITHUB_ENTERPRISE", "GITLAB", "GITLAB_SELF_MANAGED", "NO_SOURCE", "S3"], var.primary_source.type)
    error_message = "primary_source.type must be a supported CodeBuild source type."
  }

  validation {
    condition = contains(["CODEPIPELINE", "NO_SOURCE"], var.primary_source.type) ? (
      try(var.primary_source.location, null) == null
    ) : try(var.primary_source.location, null) != null
    error_message = "primary_source.location must be omitted for CODEPIPELINE and NO_SOURCE, and is required for every other source type."
  }

  validation {
    condition     = try(var.primary_source.git_clone_depth, null) == null ? true : var.primary_source.git_clone_depth >= 0
    error_message = "primary_source.git_clone_depth must be at least 0 when specified."
  }

  validation {
    condition     = try(var.primary_source.auth, null) == null ? true : contains(["BITBUCKET", "CODECOMMIT", "GITHUB", "GITHUB_ENTERPRISE", "GITLAB", "GITLAB_SELF_MANAGED"], var.primary_source.type)
    error_message = "primary_source.auth is supported only with repository source types."
  }

  validation {
    condition     = try(var.primary_source.build_status_config, null) == null ? true : contains(["BITBUCKET", "GITHUB", "GITHUB_ENTERPRISE"], var.primary_source.type)
    error_message = "primary_source.build_status_config is supported only with BITBUCKET, GITHUB, and GITHUB_ENTERPRISE sources."
  }
}

# -----------------------------------------------------------------------------
# Optional project configuration
# -----------------------------------------------------------------------------

variable "auto_retry_limit" {
  description = "Maximum number of automatic retries after a failed build. This argument requires AWS provider v6.16 or later."
  type        = number
  default     = null

  validation {
    condition     = var.auto_retry_limit == null ? true : var.auto_retry_limit >= 0
    error_message = "auto_retry_limit must be at least 0 when specified."
  }
}

variable "badge_enabled" {
  description = "Whether to generate a publicly accessible build badge URL."
  type        = bool
  default     = false
}

variable "build_batch_config" {
  description = "Optional batch build configuration. restrictions limits allowed compute types and concurrent builds for a batch."
  type = object({
    service_role      = string
    combine_artifacts = optional(bool)
    timeout_in_mins   = optional(number)
    restrictions = optional(object({
      compute_types_allowed  = optional(list(string))
      maximum_builds_allowed = optional(number)
    }))
  })
  default = null

  validation {
    condition     = var.build_batch_config == null ? true : (try(var.build_batch_config.restrictions.maximum_builds_allowed, null) == null ? true : var.build_batch_config.restrictions.maximum_builds_allowed >= 1)
    error_message = "build_batch_config.restrictions.maximum_builds_allowed must be at least 1 when specified."
  }
}

variable "build_timeout" {
  description = "Maximum number of minutes CodeBuild waits before timing out a build. AWS allows 5 to 2160 minutes."
  type        = number
  default     = null

  validation {
    condition     = var.build_timeout == null ? true : var.build_timeout >= 5 && var.build_timeout <= 2160
    error_message = "build_timeout must be between 5 and 2160 minutes when specified."
  }
}

variable "cache" {
  description = "Optional build cache configuration. location is required when type is S3 and must be omitted for NO_CACHE."
  type = object({
    type            = string
    cache_namespace = optional(string)
    location        = optional(string)
    modes           = optional(list(string))
  })
  default = null

  validation {
    condition     = var.cache == null ? true : contains(["LOCAL", "NO_CACHE", "S3"], var.cache.type)
    error_message = "cache.type must be LOCAL, NO_CACHE, or S3 when configured."
  }

  validation {
    condition     = var.cache == null ? true : (var.cache.type != "S3" ? true : try(var.cache.location, null) != null)
    error_message = "cache.location is required when cache.type is S3."
  }

  validation {
    condition     = var.cache == null ? true : (var.cache.type != "NO_CACHE" ? true : try(var.cache.location, null) == null)
    error_message = "cache.location must be omitted when cache.type is NO_CACHE."
  }

  validation {
    condition     = var.cache == null ? true : alltrue([for mode in coalesce(var.cache.modes, []) : contains(["LOCAL_CUSTOM_CACHE", "LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"], mode)])
    error_message = "cache.modes may contain only LOCAL_CUSTOM_CACHE, LOCAL_DOCKER_LAYER_CACHE, or LOCAL_SOURCE_CACHE."
  }
}

variable "concurrent_build_limit" {
  description = "Maximum number of concurrent builds allowed for the project."
  type        = number
  default     = null

  validation {
    condition     = var.concurrent_build_limit == null ? true : var.concurrent_build_limit >= 1
    error_message = "concurrent_build_limit must be at least 1 when specified."
  }
}

variable "description" {
  description = "Description that identifies the build project. It must be at most 255 characters."
  type        = string
  default     = null

  validation {
    condition     = var.description == null ? true : length(var.description) <= 255
    error_message = "description must be at most 255 characters when specified."
  }
}

variable "encryption_key" {
  description = "ARN or alias of the KMS key used to encrypt build output artifacts."
  type        = string
  default     = null

  validation {
    condition     = var.encryption_key == null ? true : length(var.encryption_key) >= 1
    error_message = "encryption_key must not be empty when specified."
  }
}

variable "file_system_locations" {
  description = "EFS file-system locations available to builds."
  type = set(object({
    identifier    = string
    location      = string
    mount_options = optional(string)
    mount_point   = string
    type          = string
  }))
  default = []

  validation {
    condition     = alltrue([for file_system_location in var.file_system_locations : file_system_location.type == "EFS"])
    error_message = "file_system_locations[*].type must be EFS."
  }
}

variable "logs_config" {
  description = "Optional CloudWatch Logs and S3 logs configuration. For each log destination, group/location and related fields must be omitted when status is DISABLED."
  type = object({
    cloudwatch_logs = optional(object({
      group_name  = optional(string)
      status      = optional(string)
      stream_name = optional(string)
    }))
    s3_logs = optional(object({
      bucket_owner_access = optional(string)
      encryption_disabled = optional(bool)
      location            = optional(string)
      status              = optional(string)
    }))
  })
  default = null

  validation {
    condition     = var.logs_config == null ? true : (try(var.logs_config.cloudwatch_logs.status, null) == null ? true : contains(["DISABLED", "ENABLED"], var.logs_config.cloudwatch_logs.status))
    error_message = "logs_config.cloudwatch_logs.status must be DISABLED or ENABLED when specified."
  }

  validation {
    condition     = var.logs_config == null ? true : (try(var.logs_config.s3_logs.status, null) == null ? true : contains(["DISABLED", "ENABLED"], var.logs_config.s3_logs.status))
    error_message = "logs_config.s3_logs.status must be DISABLED or ENABLED when specified."
  }

  validation {
    condition     = var.logs_config == null ? true : (try(var.logs_config.s3_logs.bucket_owner_access, null) == null ? true : contains(["FULL", "NONE", "READ_ONLY"], var.logs_config.s3_logs.bucket_owner_access))
    error_message = "logs_config.s3_logs.bucket_owner_access must be FULL, NONE, or READ_ONLY when specified."
  }

  validation {
    condition     = var.logs_config == null ? true : (try(var.logs_config.s3_logs.status, null) != "DISABLED" ? true : try(var.logs_config.s3_logs.location, null) == null)
    error_message = "logs_config.s3_logs.location must be omitted when logs_config.s3_logs.status is DISABLED."
  }

  validation {
    condition     = var.logs_config == null ? true : (try(var.logs_config.s3_logs.status, null) != "DISABLED" ? true : try(var.logs_config.s3_logs.bucket_owner_access, null) == null && try(var.logs_config.s3_logs.encryption_disabled, null) == null)
    error_message = "logs_config.s3_logs.bucket_owner_access and encryption_disabled must be omitted when logs_config.s3_logs.status is DISABLED."
  }

  validation {
    condition     = var.logs_config == null ? true : (try(var.logs_config.cloudwatch_logs.status, null) != "DISABLED" ? true : try(var.logs_config.cloudwatch_logs.group_name, null) == null && try(var.logs_config.cloudwatch_logs.stream_name, null) == null)
    error_message = "logs_config.cloudwatch_logs.group_name and stream_name must be omitted when logs_config.cloudwatch_logs.status is DISABLED."
  }
}

variable "project_visibility" {
  description = "Visibility of the project. PUBLIC projects can expose build information publicly."
  type        = string
  default     = "PRIVATE"

  validation {
    condition     = contains(["PRIVATE", "PUBLIC"], var.project_visibility)
    error_message = "project_visibility must be PRIVATE or PUBLIC."
  }
}

variable "queued_timeout" {
  description = "Maximum number of minutes a build can remain queued. AWS allows 5 to 480 minutes."
  type        = number
  default     = null

  validation {
    condition     = var.queued_timeout == null ? true : var.queued_timeout >= 5 && var.queued_timeout <= 480
    error_message = "queued_timeout must be between 5 and 480 minutes when specified."
  }
}

variable "region" {
  description = "AWS Region where the project is managed. This AWS provider v6 argument defaults to the provider-configured Region."
  type        = string
  default     = null
}

variable "resource_access_role" {
  description = "ARN of the IAM role used to access resources required by a public CodeBuild project."
  type        = string
  default     = null
}

variable "secondary_artifacts" {
  description = "Secondary build output artifacts. AWS allows at most 12 secondary artifacts. location is required for S3 artifacts."
  type = set(object({
    artifact_identifier    = string
    type                   = string
    bucket_owner_access    = optional(string)
    encryption_disabled    = optional(bool)
    location               = optional(string)
    name                   = optional(string)
    namespace_type         = optional(string)
    override_artifact_name = optional(bool)
    packaging              = optional(string)
    path                   = optional(string)
  }))
  default = []

  validation {
    condition     = length(var.secondary_artifacts) <= 12 && alltrue([for artifact in var.secondary_artifacts : contains(["CODEPIPELINE", "NO_ARTIFACTS", "S3"], artifact.type) && (artifact.type != "S3" || try(artifact.location, null) != null) && (try(artifact.encryption_disabled, null) == null || artifact.type == "S3")])
    error_message = "secondary_artifacts may contain at most 12 entries; each type must be CODEPIPELINE, NO_ARTIFACTS, or S3, S3 artifacts require location, and encryption_disabled is supported only for S3 artifacts."
  }
}

variable "secondary_source_versions" {
  description = "Versions for secondary sources. Every source_identifier must match a configured secondary source, and AWS allows at most 12 entries."
  type = set(object({
    source_identifier = string
    source_version    = string
  }))
  default = []

  validation {
    condition     = length(var.secondary_source_versions) <= 12
    error_message = "secondary_source_versions may contain at most 12 entries."
  }
}

variable "secondary_sources" {
  description = "Secondary build input sources. AWS allows at most 12 entries. location is required except for CODEPIPELINE and NO_SOURCE; auth and git_submodules_config are optional single blocks. build_status_config is supported only for GITHUB, GITHUB_ENTERPRISE, and BITBUCKET sources."
  type = set(object({
    source_identifier   = string
    type                = string
    buildspec           = optional(string)
    git_clone_depth     = optional(number)
    insecure_ssl        = optional(bool)
    location            = optional(string)
    report_build_status = optional(bool)
    auth = optional(object({
      resource = string
      type     = string
    }))
    build_status_config = optional(object({
      context    = optional(string)
      target_url = optional(string)
    }))
    git_submodules_config = optional(object({
      fetch_submodules = bool
    }))
  }))
  default = []

  validation {
    condition = length(var.secondary_sources) <= 12 && alltrue([
      for source in var.secondary_sources : contains(["BITBUCKET", "CODECOMMIT", "CODEPIPELINE", "GITHUB", "GITHUB_ENTERPRISE", "GITLAB", "GITLAB_SELF_MANAGED", "NO_SOURCE", "S3"], source.type) && (contains(["CODEPIPELINE", "NO_SOURCE"], source.type) ? try(source.location, null) == null : try(source.location, null) != null) && (try(source.git_clone_depth, null) == null ? true : source.git_clone_depth >= 0) && (try(source.auth, null) == null ? true : contains(["BITBUCKET", "CODECOMMIT", "GITHUB", "GITHUB_ENTERPRISE", "GITLAB", "GITLAB_SELF_MANAGED"], source.type)) && (try(source.build_status_config, null) == null ? true : contains(["BITBUCKET", "GITHUB", "GITHUB_ENTERPRISE"], source.type))
    ])
    error_message = "secondary_sources may contain at most 12 entries; each source type and location must be valid, auth is supported only for repository source types, build_status_config is supported only for BITBUCKET, GITHUB, and GITHUB_ENTERPRISE sources, and git_clone_depth must be at least 0."
  }
}

variable "source_version" {
  description = "Version of the primary source to build."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to assign to the project. AWS allows at most 50 tags; keys must be 1 to 128 characters and values at most 256 characters."
  type        = map(string)
  default     = {}

  validation {
    condition = length(var.tags) <= 50 && alltrue([
      for key, value in var.tags : length(key) >= 1 && length(key) <= 128 && length(value) <= 256
    ])
    error_message = "tags must contain at most 50 entries. Tag keys must be 1 to 128 characters and values must be at most 256 characters."
  }
}

variable "vpc_config" {
  description = "Optional VPC configuration. vpc_id, at least one subnet, and at least one security group are required together."
  type = object({
    security_group_ids = set(string)
    subnets            = set(string)
    vpc_id             = string
  })
  default = null

  validation {
    condition     = var.vpc_config == null ? true : length(var.vpc_config.security_group_ids) >= 1 && length(var.vpc_config.subnets) >= 1 && length(var.vpc_config.vpc_id) >= 1
    error_message = "vpc_config requires vpc_id, at least one subnet, and at least one security group."
  }
}
