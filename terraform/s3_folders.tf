# PART 9: Folder Structure
# raw/ processed/ curated/ temp/ archive/

resource "aws_s3_object" "folders" {
  for_each = toset(local.folders)

  bucket       = aws_s3_bucket.data_lake.id
  key          = each.value
  content_type = "application/x-directory"

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.data_lake]
}
