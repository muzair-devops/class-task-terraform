provider "aws" {
  region = "us-east-1"
}

# -------------------------------
# DynamoDB Table
# -------------------------------
resource "aws_dynamodb_table" "be_dynamodb" {
  name           = "be_dynamodb"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "be_dynamodb"
    Environment = "dev"
  }
}

# -------------------------------
# IAM Role for Lambda
# -------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "lambda_dynamodb_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# -------------------------------
# IAM Policy for Lambda (DynamoDB Only)
# -------------------------------
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_dynamodb_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "DynamoDBAccess",
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan"
        ],
        Resource = aws_dynamodb_table.be_dynamodb.arn
      }
    ]
  })
}

# -------------------------------
# Lambda Function
# -------------------------------
resource "aws_lambda_function" "be_lambda" {
  function_name = "be_lambda_function"
  filename      = "lambda_function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  role = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.be_dynamodb.name
    }
  }

  # Optional: ensures Lambda updates when code changes
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# -------------------------------
# Lambda Function URL
# -------------------------------
resource "aws_lambda_function_url" "be_lambda_url" {
  function_name      = aws_lambda_function.be_lambda.function_name
  authorization_type = "NONE"  # public access
  cors {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }
}

# -------------------------------
# Outputs
# -------------------------------
output "lambda_function_name" {
  value = aws_lambda_function.be_lambda.function_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.be_dynamodb.name
}

output "lambda_function_name" {
  value = aws_lambda_function.be_lambda.function_name
}
