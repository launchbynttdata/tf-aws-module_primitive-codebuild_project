logical_product_family  = "codex"
logical_product_service = "codebuild"
class_env               = "dev"
instance_env            = 1
instance_resource       = 1

resource_names_map = {
  artifacts = {
    name       = "codebuildartifacts"
    max_length = 63
  }
  project = {
    name       = "codebuildproject"
    max_length = 150
  }
  role = {
    name       = "codebuildrole"
    max_length = 64
  }
}

description    = "Complete example for the aws_codebuild_project primitive module."
build_timeout  = 45
queued_timeout = 30

tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Example     = "complete"
}
