resource "aws_s3_bucket" "mybucket" {
  bucket = "mybucket-13-03-2021"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "107b3130-6e28-4017-abd8-fc3f85950f55"
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
