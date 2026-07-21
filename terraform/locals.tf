locals {
  common_tags = var.tags

  account_id = data.aws_caller_identity.current.account_id

  data_lake_bucket_name  = "data-lake-prod-${local.account_id}"
  logs_bucket_name       = "data-lake-prod-logs-${local.account_id}"
  cloudtrail_bucket_name = "data-lake-prod-cloudtrail-${local.account_id}"

  folders = ["raw/", "processed/", "curated/", "temp/", "archive/"]

  allowed_role_arns = [
    data.aws_iam_role.data_engineer.arn,
    data.aws_iam_role.glue_service.arn,
    data.aws_iam_role.redshift.arn,
  ]
}
