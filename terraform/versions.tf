terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Shared state bucket + lock table already created by sibling labs in
  # this account (Datasync-Batch-Ingestion-from-On-premises) — reused here
  # under a distinct key rather than standing up a separate backend.
  # Backend blocks can't use variables, hence the hardcoded values.
  backend "s3" {
    bucket         = "data-lake-825765383386"
    key            = "terraform/s3-data-lake-foundation.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "datasync-terraform-locks"
    encrypt        = true
  }
}
