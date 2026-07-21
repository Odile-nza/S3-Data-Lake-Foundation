# PART 5: Bucket Policy (Key Rules)
#   - Enforce HTTPS only
#   - Block unencrypted uploads
#   - Allow IAM roles only: DataEngineerRole, GlueServiceRole, RedshiftIAMRole

data "aws_iam_policy_document" "data_lake_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [aws_s3_bucket.data_lake.arn, "${aws_s3_bucket.data_lake.arn}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.data_lake.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }

  statement {
    sid    = "AllowDataLakeRoleAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.allowed_role_arns
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.data_lake.arn, "${aws_s3_bucket.data_lake.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  policy = data.aws_iam_policy_document.data_lake_bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.data_lake]
}
