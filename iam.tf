resource "aws_iam_role" "s3_replication_role" {
  name = "s3_replication_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  # Attach the S3 replication policy
  inline_policy {
    name = "s3_replication_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging",
            "s3:GetObjectRetention",
            "s3:GetObjectLegalHold"
          ]
          Resource = [
            "${aws_s3_bucket.source_bucket.arn}/*",
            "aws_s3_bucket.source_bucket.arn"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags",
            "s3:ReplicateObjectVersionTagging"
          ]
          Resource = [
            "${aws_s3_bucket.destination_bucket.arn}/*",
            "aws_s3_bucket.destination_bucket.arn"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Resource = [
            aws_kms_key.source.key_id,
            aws_kms_key.destination.key_id
          ]
        }
      ]
    })
  }
}



resource "aws_iam_role" "crud_role" {
  name = "crud_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "crud_policy" {
  name        = "crud_policy"
  description = "CRUD policy for S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.source_bucket.arn,
          aws_s3_bucket.destination_bucket.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crud_policy_attachment" {
  policy_arn = aws_iam_policy.crud_policy.arn
  role       = aws_iam_role.crud_role.name
}

# Create the CodePipeline IAM role
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the necessary policies to the CodePipeline role
resource "aws_iam_role_policy_attachment" "codepipeline_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipelineFullAccess"
  role       = aws_iam_role.codepipeline_role.name
}

# Get the latest commit ID from the CodeCommit repository
data "aws_codecommit_repository" "latest_commit" {
  repository_name = aws_codecommit_repository.my_repo.repository_name
}

# Create the S3 bucket for the CodePipeline artifacts
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "my-codepipeline-bucket"
}

# Create the CodePipeline
resource "aws_codepipeline" "my_pipeline" {
  name     = "my-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        RepositoryName = aws_codecommit_repository.my_repo.repository_name
        BranchName     = "main"
      }

      run_order = 1
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["SourceOutput"]
      version         = "1"

      configuration = {
        ApplicationName               = "my-application"
        DeploymentGroupName           = "my-deployment-group"
        DeploymentConfigName          = "CodeDeployDefault.OneAtATime"
        S3Bucket                      = aws_s3_bucket.codepipeline_bucket.bucket
        S3ObjectKey                   = "source.zip"
        IgnoreApplicationStopFailures = "true"
      }

      run_order = 1
    }
  }
}
