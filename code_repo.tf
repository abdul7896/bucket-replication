resource "aws_codecommit_repository" "my_repo" {
  repository_name = "abdul-repo"
  description     = "S3 Project repository"
  default_branch  = "main"
  tags = {
    Terraform = "true"
  }
}
