# PART 4: Create S3 Bucket

resource "aws_s3_bucket" "data_lake" {
  bucket = local.data_lake_bucket_name
}

# Object Ownership: ACLs disabled
resource "aws_s3_bucket_ownership_controls" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block Public Access: Enable All
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# PART 5: Security Configuration — SSE-S3 encryption, bucket key enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# PART 6: Versioning
resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

# PART 7: Access Logging
resource "aws_s3_bucket_logging" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}
