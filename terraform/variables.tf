variable "aws_region" {
  description = "AWS region for the data lake. The lab doc says us-east-1, but this account's actual infrastructure (data-platform-vpc, Lab 1.2) lives in eu-west-1 — matching that instead."
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "production"
}

# --- IAM roles created in Lab 1.1 (prerequisite) -----------------------
# These roles are expected to already exist; Terraform looks them up via
# data sources rather than creating them, and grants them access to the
# data lake bucket.

variable "data_engineer_role_name" {
  description = "Name of the pre-existing DataEngineerRole IAM role."
  type        = string
  default     = "DataEngineerRole"
}

variable "glue_service_role_name" {
  description = "Name of the pre-existing GlueServiceRole IAM role."
  type        = string
  default     = "GlueServiceRole"
}

variable "redshift_role_name" {
  description = "Name of the pre-existing RedshiftIAMRole IAM role."
  type        = string
  default     = "RedshiftIAMRole"
}

# --- Lifecycle policy thresholds ----------------------------------------

variable "processed_glacier_days" {
  description = "Days before processed/ objects transition to Glacier."
  type        = number
  default     = 90
}

variable "processed_deep_archive_days" {
  description = "Days before processed/ objects transition to Deep Archive."
  type        = number
  default     = 180
}

variable "temp_expiration_days" {
  description = "Days before temp/ objects are deleted."
  type        = number
  default     = 1
}

variable "archive_deep_archive_days" {
  description = "Days before archive/ objects transition to Deep Archive."
  type        = number
  default     = 30
}

variable "archive_expiration_days" {
  description = "Days before archive/ objects are deleted (7 years)."
  type        = number
  default     = 2555
}

# --- Test data -----------------------------------------------------------

variable "upload_test_data" {
  description = "Whether to upload test_customers.csv to raw/. Set to false and re-apply to perform the Part 15 teardown (delete test file, keep everything else)."
  type        = bool
  default     = true
}

# --- Tagging ---------------------------------------------------------------

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    Environment = "Production"
    Owner       = "DataEngineering"
    Purpose     = "DataLake"
    CostCenter  = "Analytics"
  }
}
