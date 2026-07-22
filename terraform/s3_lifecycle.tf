# PART 10: Lifecycle Policies

resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  # Policy 1: Processed Data
  rule {
    id     = "processed-data-lifecycle"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    transition {
      days          = var.processed_glacier_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.processed_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }
  }

  # Policy 2: Temp Data
  rule {
    id     = "temp-data-expiration"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    expiration {
      days = var.temp_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.temp_expiration_days
    }
  }

  # Policy 3: Archive Data
  rule {
    id     = "archive-data-lifecycle"
    status = "Enabled"

    filter {
      prefix = "archive/"
    }

    transition {
      days          = var.archive_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.archive_expiration_days
    }
  }

  # Cleans up stray multipart uploads left by interrupted transfers,
  # bucket-wide (not scoped to any one prefix).
  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.data_lake]
}
