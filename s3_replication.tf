module "s3-replication" {
  source            = "./modules/s3-replication"
  source_bucket_name = "my-source-bucket"
  replica_bucket_name = "my-replica-bucket"
  log_bucket_name = "my-log-bucket"
}