data "aws_caller_identity" "current" {}

data "aws_iam_role" "data_engineer" {
  name = var.data_engineer_role_name
}

data "aws_iam_role" "glue_service" {
  name = var.glue_service_role_name
}

data "aws_iam_role" "redshift" {
  name = var.redshift_role_name
}
