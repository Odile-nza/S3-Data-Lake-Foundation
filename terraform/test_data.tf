# PART 12: Test Data Upload
# PART 15: Teardown — set upload_test_data=false and re-apply to delete
# just this object while keeping the bucket, IAM roles, VPC, and logs.

resource "aws_s3_object" "test_customers" {
  count = var.upload_test_data ? 1 : 0

  bucket                 = aws_s3_bucket.data_lake.id
  key                    = "raw/test_customers.csv"
  source                 = "${path.module}/test_customers.csv"
  etag                   = filemd5("${path.module}/test_customers.csv")
  content_type           = "text/csv"
  server_side_encryption = "AES256"

  depends_on = [aws_s3_object.folders]
}
