# Create the source S3 bucket
resource "aws_s3_bucket" "source_bucket" {
  bucket        = var.source_bucket_name
  force_destroy = true  # Allow bucket to be destroyed even if not empty
}

# Configure server-side encryption for the source bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  bucket = aws_s3_bucket.source_bucket.id  # Reference the source bucket by its ID

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.source.arn  # Use the source KMS key for server-side encryption
      sse_algorithm     = "aws:kms"  # Use AWS KMS encryption algorithm
    }
  }
}

# Create the replica S3 bucket
resource "aws_s3_bucket" "replica_bucket" {
  bucket        = var.replica_bucket_name
  force_destroy = true  # Allow bucket to be destroyed even if not empty
}

# Configure server-side encryption for the replica bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  bucket = aws_s3_bucket.replica_bucket.id  # Reference the replica bucket by its ID

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.replica.arn  # Use the replica KMS key for server-side encryption
      sse_algorithm     = "aws:kms"  # Use AWS KMS encryption algorithm
    }
  }
}

# Create the logging S3 bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket        = var.log_bucket_name
  force_destroy = true  # Allow bucket to be destroyed even if not empty
}

# Configure server-side encryption for the logging bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  bucket = aws_s3_bucket.log_bucket.id  # Reference the logging bucket by its ID

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.log.arn  # Use the logging KMS key for server-side encryption
      sse_algorithm     = "aws:kms"  # Use AWS KMS encryption algorithm
    }
  }
}

# Configure bucket logging for both source and replica buckets
resource "aws_s3_bucket_logging" "source_bucket_logging" {
  bucket        = aws_s3_bucket.source_bucket.id  # Reference the source bucket by its ID
  target_bucket = aws_s3_bucket.log_bucket.id     # Reference the logging bucket by its ID
  target_prefix = "log/"                          # Use "log/" as prefix for the logs in the logging bucket
}

resource "aws_s3_bucket_logging" "replica_bucket_logging" {
  bucket        = aws_s3_bucket.replica_bucket.id  # Reference the replica bucket by its ID
  target_bucket = aws_s3_bucket.log_bucket.id      # Reference the logging bucket by its ID
  target_prefix = "log/"                           # Use "log/" as prefix for the logs in the logging bucket
}

# Create KMS keys for source and replica buckets
resource "aws_kms_key" "source" {
  deletion_window_in_days = 10  # Set the key retention period to 10 days
}

resource "aws_kms_key" "replica" {
  deletion_window_in_days = 10  # Set the key retention period to 10 days
}

# Create KMS aliases for source and replica keys
resource "aws_kms_alias" "source" {
  name          = "alias/source-key-alias"
  target_key_id = aws_kms_key.source.key_id
}

resource "aws_kms_alias" "replica" {
  name          = "alias/replica-key-alias"
  target_key_id = aws_kms_key.replica.key_id
}

# Create KMS key for logging
resource "aws_kms_key" "log" {
  deletion_window_in_days = 10  # Set the key retention period to 10 days
}

# Create KMS alias for logging key
resource "aws_kms_alias" "log" {
  name          = "alias/log-key-alias"
  target_key_id = aws_kms_key.log.key_id
}
