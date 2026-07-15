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

output "id" {
  description = "The CodeBuild project ID."
  value       = module.project.id
}

output "arn" {
  description = "The CodeBuild project ARN."
  value       = module.project.arn
}

output "name" {
  description = "The CodeBuild project name."
  value       = module.project.name
}

output "region" {
  description = "The region where the CodeBuild project is managed."
  value       = module.project.region
}

output "expected_artifact_bucket" {
  description = "The S3 bucket configured for the project artifacts."
  value       = var.artifacts == null ? aws_s3_bucket.artifacts.id : (var.artifacts.location == null ? "" : var.artifacts.location)
}

output "expected_build_timeout" {
  description = "The expected build timeout in minutes for the example."
  value       = coalesce(var.build_timeout, 60) # AWS service default
}

output "expected_encryption_key_arn" {
  description = "The customer-managed KMS key expected to encrypt the project output artifacts."
  value       = coalesce(var.encryption_key, aws_kms_key.artifacts.arn)
}

output "expected_description" {
  description = "The description expected on the project."
  value       = var.description
}

output "expected_tags" {
  description = "The tags expected on the project."
  value       = var.tags
}

output "expected_badge_enabled" {
  description = "Whether the example expects a project build badge."
  value       = var.badge_enabled
}

output "expected_cache_type" {
  description = "The cache type expected on the project, when configured."
  value       = try(var.cache.type, "")
}

output "expected_environment_variables" {
  description = "The environment variables expected on the project."
  value = var.environment == null ? {} : {
    for environment_variable in var.environment.environment_variables : environment_variable.name => environment_variable.value
  }
}

output "expected_environment_compute_type" {
  description = "The expected CodeBuild compute type for the example."
  value       = var.environment == null ? "BUILD_GENERAL1_SMALL" : var.environment.compute_type
}

output "expected_environment_type" {
  description = "The expected CodeBuild environment type for the example."
  value       = var.environment == null ? "LINUX_CONTAINER" : var.environment.type
}

output "expected_source_type" {
  description = "The expected primary source type for the example."
  value       = var.primary_source == null ? "NO_SOURCE" : var.primary_source.type
}
