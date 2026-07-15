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

variable "logical_product_family" {
  description = "Logical product family for generated resource names."
  type        = string
}

variable "logical_product_service" {
  description = "Logical product service for generated resource names."
  type        = string
}

variable "class_env" {
  description = "Environment class for generated resource names."
  type        = string
}

variable "instance_env" {
  description = "Environment instance number for generated resource names."
  type        = number
}

variable "instance_resource" {
  description = "Resource instance number for generated resource names."
  type        = number
}

variable "resource_names_map" {
  description = "Resource name configuration keyed by resource role."
  type = map(object({
    name       = string
    max_length = number
  }))
}

variable "name" {
  description = "Optional override for the generated CodeBuild project name."
  type        = string
  default     = null
}

variable "service_role" {
  description = "Optional override for the example CodeBuild service role ARN."
  type        = string
  default     = null
}

variable "artifacts" {
  description = "Optional override for the secure S3 artifact configuration used by the example."
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
  default = null
}

variable "environment" {
  description = "Optional override for the CodeBuild environment configuration."
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
  default = null
}

variable "primary_source" {
  description = "Optional override for the no-source inline-buildspec configuration used by the example."
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
  default = null
}

variable "auto_retry_limit" {
  description = "Maximum number of automatic build retries."
  type        = number
  default     = null
}

variable "badge_enabled" {
  description = "Whether build badges are enabled."
  type        = bool
  default     = false
}

variable "build_batch_config" {
  description = "Optional batch build configuration."
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
}

variable "build_timeout" {
  description = "Maximum build duration in minutes."
  type        = number
  default     = null
}

variable "cache" {
  description = "Optional build cache configuration."
  type = object({
    type            = string
    cache_namespace = optional(string)
    location        = optional(string)
    modes           = optional(list(string))
  })
  default = null
}

variable "concurrent_build_limit" {
  description = "Maximum number of concurrent builds."
  type        = number
  default     = null
}

variable "description" {
  description = "Description for the CodeBuild project."
  type        = string
  default     = null
}

variable "encryption_key" {
  description = "Optional override for the example customer-managed artifact encryption key ARN. The external key policy and IAM policy must grant the example CodeBuild role KMS permissions."
  type        = string
  default     = null
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
}

variable "logs_config" {
  description = "Optional CloudWatch Logs and S3 logs configuration."
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
}

variable "project_visibility" {
  description = "Visibility of the CodeBuild project."
  type        = string
  default     = "PRIVATE"
}

variable "queued_timeout" {
  description = "Maximum queue duration in minutes."
  type        = number
  default     = null
}

variable "region" {
  description = "Optional AWS provider v6 per-resource region override."
  type        = string
  default     = null
}

variable "resource_access_role" {
  description = "Optional public-project resource access role ARN."
  type        = string
  default     = null
}

variable "secondary_artifacts" {
  description = "Secondary artifact configurations."
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
}

variable "secondary_source_versions" {
  description = "Versions for secondary sources."
  type = set(object({
    source_identifier = string
    source_version    = string
  }))
  default = []
}

variable "secondary_sources" {
  description = "Secondary source configurations."
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
}

variable "source_version" {
  description = "Optional version of the primary source to build."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all example resources."
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "Optional VPC configuration for the CodeBuild project."
  type = object({
    security_group_ids = set(string)
    subnets            = set(string)
    vpc_id             = string
  })
  default = null
}
