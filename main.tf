# Create a KMS key
resource "aws_kms_key" "source" {
  description              = "My KMS key"
  enable_key_rotation      = true
  key_usage                = "ENCRYPT_DECRYPT"
  deletion_window_in_days  = 7
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

# Create a KMS key
resource "aws_kms_key" "destination" {
  description              = "My KMS key"
  enable_key_rotation      = true
  key_usage                = "ENCRYPT_DECRYPT"
  deletion_window_in_days  = 7
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

# Create source bucket
resource "aws_s3_bucket" "source_bucket" {
  bucket = "my-source-bucket"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.source.key_id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

# Create destination bucket
resource "aws_s3_bucket" "destination_bucket" {
  bucket = "my-destination-bucket"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.destination.key_id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}