terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend config values (bucket/key/region/dynamodb_table) are supplied
  # at `terraform init` time via -backend-config, either from a local
  # backend.hcl (gitignored) or from the CI/CD pipeline using repo secrets.
  backend "s3" {}
}
