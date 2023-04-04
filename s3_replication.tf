module "s3-replication" {
  source              = "./modules/s3-replication"
  source_bucket_name  = "my-source-bucket78946599"
  replica_bucket_name = "my-replica-bucket78946599"
  log_bucket_name     = "my-log-bucket78946599"
}