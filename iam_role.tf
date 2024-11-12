#  IAM Role for Lambda Functions (Execution Role)

resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-LambdaExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}


# IAM policies for both DynamoDB and KMS & secret manager

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-LambdaAccessPolicy"
  description = "Policy for Lambda to access DynamoDB, KMS keys, and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # KMS Access for Encryption, Decryption, and Signing
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:Sign"
        ]
        Resource = [
          aws_kms_key.jwt_signing_key.arn, # Correct KMS key for signing JWT
          aws_kms_key.encryption_key.arn   # Correct KMS key for encrypting card data
        ]
      },

      # DynamoDB Access for common actions
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${aws_dynamodb_table.tokenization_table.name}",
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${aws_dynamodb_table.tokenization_table.name}/index/*"
        ]
      },

      # Secrets Manager Access for KMS Key IDs
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.jwt_signing_key_secret.arn,
          aws_secretsmanager_secret.encryption_key_secret.arn
        ]
      }
    ]
  })
}


# Attach the combined policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_kms_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
 