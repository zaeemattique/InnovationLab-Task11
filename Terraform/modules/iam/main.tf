# IAM role for EC2 instances (instance profile)
resource "aws_iam_role" "ec2_role" {
    name = "eb-ec2-role"
    assume_role_policy = data.aws_iam_policy_document.ec2_assume_policy.json
}

data "aws_iam_policy_document" "ec2_assume_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
        type = "Service"
        identifiers = ["ec2.amazonaws.com"]
        }
    }
}

resource "aws_iam_role_policy_attachment" "ec2_managed_attach" {
    role = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "ec2_eb_s3" {
    role = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "eb-ec2-instance-profile"
    role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role" "beanstalk_service_role" {
    name = "aws-elasticbeanstalk-service-role"
    assume_role_policy = data.aws_iam_policy_document.beanstalk_assume_policy.json
}

data "aws_iam_policy_document" "beanstalk_assume_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
        type = "Service"
        identifiers = ["elasticbeanstalk.amazonaws.com"]
        }
    }
}

resource "aws_iam_role_policy_attachment" "beanstalk_service_attach" {
    role = aws_iam_role.beanstalk_service_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

data "aws_iam_policy_document" "pipeline_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "Task11-CodePipeline-Role"  # Changed from Task8 to Task11
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume_role.json
}

# CodePipeline policy for CodeBuild permissions - ADD THIS POLICY
resource "aws_iam_role_policy" "codepipeline_codebuild_policy" {
  name = "Task11-CodePipeline-CodeBuild-Policy"  # Changed from Task8 to Task11
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCodeBuildAccess"
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetProjects",
          "codebuild:StopBuild",
          "codebuild:ListBuilds",
          "codebuild:ListBuildsForProject"
        ]
        Resource = [
          "arn:aws:codebuild:us-west-2:880958245574:project/Task11-Build-Project-Zaeem",
          "arn:aws:codebuild:us-west-2:880958245574:project/*"  
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_eb_policy" {
  name = "Task11-CodePipeline-EB-Policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "IamPassRolePermissions"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "arn:aws:iam::880958245574:role/*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ecs.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.codepipeline_bucket}",
          "arn:aws:s3:::${var.codepipeline_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = [
          var.codestar_connection_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:ListConnections",
          "codestar-connections:GetConnection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:PassConnection"
        ]
        Resource = var.codestar_connection_arn
        Condition = {
          StringEquals = {
            "codestar-connections:PassedToService" = "codepipeline.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_s3_policy" {
  name = "Task11-CodePipeline-S3-Policy"  
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCodePipelineAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          "arn:aws:s3:::${var.codepipeline_bucket}",
          "arn:aws:s3:::${var.codepipeline_bucket}/*"
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy" "codepipeline_beanstalk_policy" {
  name = "Task11-CodePipeline-ElasticBeanstalk-Policy"  
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowElasticBeanstalkAccess"
        Effect = "Allow"
        Action = [
          "elasticbeanstalk:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "sns:*",
          "cloudformation:*",
          "rds:*",
          "sqs:*",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowS3ForElasticBeanstalk"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role" "codebuild_role" {
  name = "Task11-CodeBuild-Role-Zaeem"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "Task11-CodeBuild-Policy"
  role = aws_iam_role.codebuild_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
     
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        Resource = "*"
      },

      
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.codepipeline_bucket}",
          "arn:aws:s3:::${var.codepipeline_bucket}/*"
        ]
      },

      
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },

      {
        Effect = "Allow"
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases"
        ],
        Resource = "*"
      },

      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_s3_readonly" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_cloudwatch_logs" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy" "codepipeline_logs_policy" {
  name = "Task11-CodePipeline-Logs-Policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy"
        ]
        Resource = [
          "arn:aws:logs:us-west-2:880958245574:log-group:/aws/elasticbeanstalk/*",
          "arn:aws:logs:us-west-2:880958245574:log-group:/aws/elasticbeanstalk/*:*"
        ]
      }
    ]
  })
}