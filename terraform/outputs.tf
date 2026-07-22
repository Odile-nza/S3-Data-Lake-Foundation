output "account_id" {
  description = "AWS account ID the data lake was deployed into."
  value       = local.account_id
}

output "data_lake_bucket_name" {
  description = "Name of the S3 data lake bucket."
  value       = aws_s3_bucket.data_lake.id
}

output "data_lake_bucket_arn" {
  description = "ARN of the S3 data lake bucket."
  value       = aws_s3_bucket.data_lake.arn
}

output "logs_bucket_name" {
  description = "Name of the S3 access logging bucket."
  value       = aws_s3_bucket.logs.id
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail log bucket."
  value       = aws_s3_bucket.cloudtrail.id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail audit trail."
  value       = aws_cloudtrail.data_lake_audit_trail.arn
}

output "cloudtrail_notifications_topic_arn" {
  description = "ARN of the SNS topic notified when a new CloudTrail log file is delivered."
  value       = aws_sns_topic.cloudtrail_notifications.arn
}

output "cloudtrail_cloudwatch_log_group" {
  description = "CloudWatch Logs group receiving CloudTrail events in near real time."
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "folders" {
  description = "Top-level folder structure created in the data lake bucket."
  value       = local.folders
}
