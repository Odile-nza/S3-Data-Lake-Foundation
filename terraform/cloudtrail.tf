# PART 8: CloudTrail — governance/audit trail

# Single-region lab, no DR requirement in scope — cross-region replication would double storage cost for no defined benefit here.
# Lab scope keeps SSE-S3 (no KMS CMK) to avoid the flat per-key monthly charge; SSE-S3 already gives encryption at rest.
resource "aws_s3_bucket" "cloudtrail" {
  bucket = local.cloudtrail_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Audit logs are retained indefinitely (no expiration) for compliance;
# only the storage class changes over time, and stray multipart uploads
# from interrupted log deliveries are cleaned up.
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "cloudtrail-log-storage-optimization"
    status = "Enabled"

    filter {}

    transition {
      days          = var.cloudtrail_glacier_days
      storage_class = "GLACIER"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.cloudtrail]
}

# Access logging for the CloudTrail bucket itself, delivered to the same
# logs bucket the data lake bucket uses, under a distinct prefix.
resource "aws_s3_bucket_logging" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "cloudtrail-access-logs/"
}

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.aws_region}:${local.account_id}:trail/data-lake-audit-trail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${local.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.aws_region}:${local.account_id}:trail/data-lake-audit-trail"]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [aws_s3_bucket.cloudtrail.arn, "${aws_s3_bucket.cloudtrail.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

# --- SNS notifications: new log file delivered ---------------------------

resource "aws_sns_topic" "cloudtrail_notifications" {
  name = "data-lake-cloudtrail-notifications"
}

data "aws_iam_policy_document" "cloudtrail_notifications_topic_policy" {
  statement {
    sid    = "AllowCloudTrailPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.cloudtrail_notifications.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.aws_region}:${local.account_id}:trail/data-lake-audit-trail"]
    }
  }

  statement {
    sid    = "AllowS3EventPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.cloudtrail_notifications.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.cloudtrail.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "cloudtrail_notifications" {
  arn    = aws_sns_topic.cloudtrail_notifications.arn
  policy = data.aws_iam_policy_document.cloudtrail_notifications_topic_policy.json
}

# Notify when a new CloudTrail log file lands in the bucket.
resource "aws_s3_bucket_notification" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  topic {
    topic_arn = aws_sns_topic.cloudtrail_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.cloudtrail_notifications]
}

# --- CloudWatch Logs integration ------------------------------------------

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/data-lake-audit-trail"
  retention_in_days = var.cloudtrail_cloudwatch_retention_days
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name               = "CloudTrailCloudWatchLogsRole"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_assume_role.json
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.cloudtrail.arn}:*"]
  }
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_logs" {
  name   = "CloudTrailCloudWatchLogsDelivery"
  role   = aws_iam_role.cloudtrail_cloudwatch.id
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_logs.json
}

# --- Trail -----------------------------------------------------------------

# Lab scope keeps SSE-S3 on the underlying bucket (no KMS CMK) to avoid the flat per-key monthly charge.
resource "aws_cloudtrail" "data_lake_audit_trail" {
  name           = "data-lake-audit-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.id
  sns_topic_name = aws_sns_topic.cloudtrail_notifications.name

  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.data_lake.arn}/"]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_sns_topic_policy.cloudtrail_notifications,
    aws_iam_role_policy.cloudtrail_cloudwatch_logs,
  ]
}
