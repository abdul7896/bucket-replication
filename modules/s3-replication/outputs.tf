output "source_bucket_arn" {
  value = aws_s3_bucket.source_bucket.arn
}

output "replica_bucket_arn" {
  value = aws_s3_bucket.replica_bucket.arn
}