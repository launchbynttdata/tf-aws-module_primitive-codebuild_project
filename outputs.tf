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
  description = "The ID of the project (the project ARN when created by Terraform)."
  value       = aws_codebuild_project.project.id
}

output "arn" {
  description = "The ARN of the project."
  value       = aws_codebuild_project.project.arn
}

output "name" {
  description = "The name of the project."
  value       = aws_codebuild_project.project.name
}

output "encryption_key" {
  description = "The KMS key ARN used to encrypt build output artifacts."
  value       = aws_codebuild_project.project.encryption_key
}

output "badge_url" {
  description = "The publicly accessible build badge URL when badges are enabled."
  value       = aws_codebuild_project.project.badge_url
}

output "public_project_alias" {
  description = "The project identifier used with CodeBuild public build APIs."
  value       = aws_codebuild_project.project.public_project_alias
}

output "region" {
  description = "The AWS Region where the project is managed."
  value       = aws_codebuild_project.project.region
}

output "tags_all" {
  description = "A map of all tags assigned to the project, including provider default tags."
  value       = aws_codebuild_project.project.tags_all
}
