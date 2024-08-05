terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.26"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "brawlbot"
  length = 4
}

resource "aws_s3_bucket" "brawlbot_bucket" {
  bucket        = random_pet.lambda_bucket_name.id
  force_destroy = true
}

resource "aws_s3_bucket_acl" "brawlbot_bucket_acl" {
  bucket     = aws_s3_bucket.brawlbot_bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.brawlbot_bucket_acl_ownership]
}

resource "aws_s3_bucket_ownership_controls" "brawlbot_bucket_acl_ownership" {
  bucket = aws_s3_bucket.brawlbot_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_object" "brawlbot_object" {
  bucket = aws_s3_bucket.brawlbot_bucket.id

  key    = "brawlbot-main.zip"
  source = "../src/build/brawlbot-main.zip"

  etag = filemd5("../src/build/brawlbot-main.zip")
}

resource "aws_lambda_function" "brawlbot-main" {
  function_name = "brawlbot-main"

  s3_bucket = aws_s3_bucket.brawlbot_bucket.id
  s3_key    = aws_s3_object.brawlbot_object.key

  runtime = "provided.al2023"
  handler = "lambda.handler"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "brawlbot-main" {
  name = "/aws/lambda/${aws_lambda_function.brawlbot-main.function_name}"

  retention_in_days = 5
}

resource "aws_iam_role" "lambda_exec" {
  name = "brawlbot-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
