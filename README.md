# Terraform AWS Module: CodeBuild Project (Primitive)

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: CC BY-NC-ND 4.0](https://img.shields.io/badge/License-CC_BY--NC--ND_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-nd/4.0/)

## Overview

This primitive module creates and configures one AWS CodeBuild project. It supports AWS provider v6 configuration for build environments, sources, artifacts, caches, logs, VPC access, batch builds, retries, and per-resource regions.

## Usage

```hcl
module "project" {
  source = "terraform.registry.launch.nttdata.com/module_primitive/codebuild_project/aws"

  name         = "example-project"
  service_role = aws_iam_role.codebuild.arn

  artifacts = {
    type     = "S3"
    location = aws_s3_bucket.artifacts.id
    name     = "output.zip"
    packaging = "ZIP"
  }

  environment = {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }

  primary_source = {
    type = "NO_SOURCE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        build:
          commands:
            - echo "build complete"
    EOT
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.16, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_codebuild_project.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_artifacts"></a> [artifacts](#input\_artifacts) | Primary build output artifact configuration. location is required when type is S3. | <pre>object({<br/>    type                   = string<br/>    artifact_identifier    = optional(string)<br/>    bucket_owner_access    = optional(string)<br/>    encryption_disabled    = optional(bool)<br/>    location               = optional(string)<br/>    name                   = optional(string)<br/>    namespace_type         = optional(string)<br/>    override_artifact_name = optional(bool)<br/>    packaging              = optional(string)<br/>    path                   = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_auto_retry_limit"></a> [auto\_retry\_limit](#input\_auto\_retry\_limit) | Maximum number of automatic retries after a failed build. This argument requires AWS provider v6.16 or later. | `number` | `null` | no |
| <a name="input_badge_enabled"></a> [badge\_enabled](#input\_badge\_enabled) | Whether to generate a publicly accessible build badge URL. | `bool` | `false` | no |
| <a name="input_build_batch_config"></a> [build\_batch\_config](#input\_build\_batch\_config) | Optional batch build configuration. restrictions limits allowed compute types and concurrent builds for a batch. | <pre>object({<br/>    service_role      = string<br/>    combine_artifacts = optional(bool)<br/>    timeout_in_mins   = optional(number)<br/>    restrictions = optional(object({<br/>      compute_types_allowed  = optional(list(string))<br/>      maximum_builds_allowed = optional(number)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_build_timeout"></a> [build\_timeout](#input\_build\_timeout) | Maximum number of minutes CodeBuild waits before timing out a build. AWS allows 5 to 2160 minutes. | `number` | `null` | no |
| <a name="input_cache"></a> [cache](#input\_cache) | Optional build cache configuration. location is required when type is S3 and must be omitted for NO\_CACHE. | <pre>object({<br/>    type            = string<br/>    cache_namespace = optional(string)<br/>    location        = optional(string)<br/>    modes           = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_concurrent_build_limit"></a> [concurrent\_build\_limit](#input\_concurrent\_build\_limit) | Maximum number of concurrent builds allowed for the project. | `number` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description that identifies the build project. It must be at most 255 characters. | `string` | `null` | no |
| <a name="input_encryption_key"></a> [encryption\_key](#input\_encryption\_key) | ARN or alias of the KMS key used to encrypt build output artifacts. | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Build environment configuration. registry\_credential requires image\_pull\_credentials\_type to be SERVICE\_ROLE. docker\_server, fleet, and registry\_credential are optional single blocks. | <pre>object({<br/>    compute_type                = string<br/>    image                       = string<br/>    type                        = string<br/>    certificate                 = optional(string)<br/>    image_pull_credentials_type = optional(string)<br/>    privileged_mode             = optional(bool)<br/>    docker_server = optional(object({<br/>      compute_type       = string<br/>      security_group_ids = optional(list(string))<br/>    }))<br/>    environment_variables = optional(list(object({<br/>      name  = string<br/>      value = string<br/>      type  = optional(string)<br/>    })), [])<br/>    fleet = optional(object({<br/>      fleet_arn = string<br/>    }))<br/>    registry_credential = optional(object({<br/>      credential          = string<br/>      credential_provider = string<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_file_system_locations"></a> [file\_system\_locations](#input\_file\_system\_locations) | EFS file-system locations available to builds. | <pre>set(object({<br/>    identifier    = string<br/>    location      = string<br/>    mount_options = optional(string)<br/>    mount_point   = string<br/>    type          = string<br/>  }))</pre> | `[]` | no |
| <a name="input_logs_config"></a> [logs\_config](#input\_logs\_config) | Optional CloudWatch Logs and S3 logs configuration. For each log destination, group/location and related fields must be omitted when status is DISABLED. | <pre>object({<br/>    cloudwatch_logs = optional(object({<br/>      group_name  = optional(string)<br/>      status      = optional(string)<br/>      stream_name = optional(string)<br/>    }))<br/>    s3_logs = optional(object({<br/>      bucket_owner_access = optional(string)<br/>      encryption_disabled = optional(bool)<br/>      location            = optional(string)<br/>      status              = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the CodeBuild project. It must be 2 to 150 characters, start with an alphanumeric character, and then contain only alphanumeric characters, hyphens, or underscores. | `string` | n/a | yes |
| <a name="input_primary_source"></a> [primary\_source](#input\_primary\_source) | Primary build input source. location must be omitted for CODEPIPELINE and NO\_SOURCE, and is required for every other source type. auth and git\_submodules\_config are optional single blocks. build\_status\_config is supported only for GITHUB, GITHUB\_ENTERPRISE, and BITBUCKET sources. | <pre>object({<br/>    type                = string<br/>    buildspec           = optional(string)<br/>    git_clone_depth     = optional(number)<br/>    insecure_ssl        = optional(bool)<br/>    location            = optional(string)<br/>    report_build_status = optional(bool)<br/>    auth = optional(object({<br/>      resource = string<br/>      type     = string<br/>    }))<br/>    build_status_config = optional(object({<br/>      context    = optional(string)<br/>      target_url = optional(string)<br/>    }))<br/>    git_submodules_config = optional(object({<br/>      fetch_submodules = bool<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_project_visibility"></a> [project\_visibility](#input\_project\_visibility) | Visibility of the project. PUBLIC projects can expose build information publicly. | `string` | `"PRIVATE"` | no |
| <a name="input_queued_timeout"></a> [queued\_timeout](#input\_queued\_timeout) | Maximum number of minutes a build can remain queued. AWS allows 5 to 480 minutes. | `number` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region where the project is managed. This AWS provider v6 argument defaults to the provider-configured Region. | `string` | `null` | no |
| <a name="input_resource_access_role"></a> [resource\_access\_role](#input\_resource\_access\_role) | ARN of the IAM role used to access resources required by a public CodeBuild project. | `string` | `null` | no |
| <a name="input_secondary_artifacts"></a> [secondary\_artifacts](#input\_secondary\_artifacts) | Secondary build output artifacts. AWS allows at most 12 secondary artifacts. location is required for S3 artifacts. | <pre>set(object({<br/>    artifact_identifier    = string<br/>    type                   = string<br/>    bucket_owner_access    = optional(string)<br/>    encryption_disabled    = optional(bool)<br/>    location               = optional(string)<br/>    name                   = optional(string)<br/>    namespace_type         = optional(string)<br/>    override_artifact_name = optional(bool)<br/>    packaging              = optional(string)<br/>    path                   = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_secondary_source_versions"></a> [secondary\_source\_versions](#input\_secondary\_source\_versions) | Versions for secondary sources. Every source\_identifier must match a configured secondary source, and AWS allows at most 12 entries. | <pre>set(object({<br/>    source_identifier = string<br/>    source_version    = string<br/>  }))</pre> | `[]` | no |
| <a name="input_secondary_sources"></a> [secondary\_sources](#input\_secondary\_sources) | Secondary build input sources. AWS allows at most 12 entries. location is required except for CODEPIPELINE and NO\_SOURCE; auth and git\_submodules\_config are optional single blocks. build\_status\_config is supported only for GITHUB, GITHUB\_ENTERPRISE, and BITBUCKET sources. | <pre>set(object({<br/>    source_identifier   = string<br/>    type                = string<br/>    buildspec           = optional(string)<br/>    git_clone_depth     = optional(number)<br/>    insecure_ssl        = optional(bool)<br/>    location            = optional(string)<br/>    report_build_status = optional(bool)<br/>    auth = optional(object({<br/>      resource = string<br/>      type     = string<br/>    }))<br/>    build_status_config = optional(object({<br/>      context    = optional(string)<br/>      target_url = optional(string)<br/>    }))<br/>    git_submodules_config = optional(object({<br/>      fetch_submodules = bool<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_service_role"></a> [service\_role](#input\_service\_role) | ARN of the IAM service role that allows CodeBuild to interact with dependent AWS services. | `string` | n/a | yes |
| <a name="input_source_version"></a> [source\_version](#input\_source\_version) | Version of the primary source to build. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to assign to the project. AWS allows at most 50 tags; keys must be 1 to 128 characters and values at most 256 characters. | `map(string)` | `{}` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | Optional VPC configuration. vpc\_id, at least one subnet, and at least one security group are required together. | <pre>object({<br/>    security_group_ids = set(string)<br/>    subnets            = set(string)<br/>    vpc_id             = string<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the project. |
| <a name="output_badge_url"></a> [badge\_url](#output\_badge\_url) | The publicly accessible build badge URL when badges are enabled. |
| <a name="output_encryption_key"></a> [encryption\_key](#output\_encryption\_key) | The KMS key ARN used to encrypt build output artifacts. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the project (the project ARN when created by Terraform). |
| <a name="output_name"></a> [name](#output\_name) | The name of the project. |
| <a name="output_public_project_alias"></a> [public\_project\_alias](#output\_public\_project\_alias) | The project identifier used with CodeBuild public build APIs. |
| <a name="output_region"></a> [region](#output\_region) | The AWS Region where the project is managed. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | A map of all tags assigned to the project, including provider default tags. |
<!-- END_TF_DOCS -->

## Module Development

### Pre-Requisites

The following commands should be available on your system:

- `asdf` or `mise`
- `make`
- `python3` (for pre-commit)

Additionally, your `git` user and email must be configured. Run the `make configure` command from the root of the repository to ensure that you meet these requirements.

### Pre-Commit hooks

The [.pre-commit-config.yaml](.pre-commit-config.yaml) file defines certain `pre-commit` hooks that are relevant to Terraform and Golang, as well as some common linting tasks. These will be configured for you when you run `make configure`.

### Local Validation

You should validate the changes you make to any module locally, prior to pushing your changes in a branch to GitHub.

1. Ensure that you have run `make configure` successfully.

2. Ensure you are signed into the appropriate cloud provider (e.g. AWS or Azure) for the module under test in your current console session.

3. Run the Terraform and Golang linters with the following command:

```
make lint
```

4. Once you have satisfied the linters, the following command will build example infrastructure in your configured cloud, run the tests, and then tear down the infrastructure it created:

```
make test
```

The pre-commit validations, as well as the `make lint` and `make test` targets, will all be performed in CI. Running these validations locally prior to opening a PR helps ensure a smooth review and merge process.

### Review & Merge Process

Once your change has been tested locally and your branch pushed up, open a new Pull Request for your branch to the default (main) branch of this repository.

The title of your Pull Request will determine the version bump for this change, and the title must be in [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#specification) format in order to merge. A breaking change will trigger a major version bump, a feature will trigger a minor version bump, and all other types will trigger a patch version bump.

Ensure your CI workflows are passing; seek approval from teammates and address any feedback; seek any explicit approvals required by the CODEOWNERS file. You may merge the PR as soon as all requirements are met, and a new release and tag will be automatically created for you.

### Automatic Updates

The shared configuration and workflow files in this repository are largely managed through the [launch-terraform-skeleton](https://github.com/launchbynttdata/launch-terraform-skeleton) repository. Outside of perhaps the `.gitignore` to account for specific files being generated by certain Terraform modules (e.g. Lambda functions), there should not be much cause to update these files on a per-repo basis, and making changes to them individually is discouraged.

If desired, you can check for and run these updates locally in a branch if you have the `copier` tool installed. Some example commands are included below:

```
# Check for updates, optionally checking prerelease versions
copier check-update [--prereleases]

# Run an update, using default answers if there are any. We use tasks, which requires --trust to be set.
copier update --defaults --trust [--prereleases]

# Recopy from the source, and --overwrite all templated files in the process
copier recopy --defaults --trust --overwrite [--prereleases]
```

Automatic updates will run through a scheduled workflow, and if the post-update tests are successful, the Pull Request created will automatically merge. Conflicts in the update or failures to test may leave a Pull Request outstanding, which needs to be addressed by a Launch Engineer.
