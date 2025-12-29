resource "aws_codepipeline" "Task11-CICD-Pipeline-Zaeem" {
  name     = "Task11-CICD-Pipeline-Zaeem"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.codepipeline_bucket
    type     = "S3"

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.Task11-Codestar-Connection-Zaeem.arn
        FullRepositoryId = "zaeemattique/InnovationLab-Task11"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.Task11-Build-Project-Zaeem.name
      }

      
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ElasticBeanstalk"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName = var.eb_app_name
        EnvironmentName = var.eb_env_name
      }
    }
  }
}

resource "aws_codestarconnections_connection" "Task11-Codestar-Connection-Zaeem" {
  name          = "Task11-Codestar-Connection-Zaeem"
  provider_type = "GitHub"
}

resource "aws_codebuild_project" "Task11-Build-Project-Zaeem" {
  name          = "Task11-Build-Project-Zaeem"
  description   = "Build project for Node.js application"
  service_role  = var.codebuild_role_arn
  build_timeout = 20

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}


