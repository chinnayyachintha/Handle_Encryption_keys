# Payment Processing Lambda Function
resource "aws_lambda_function" "payment_processing_lambda" {
  function_name = "${var.project_name}-Function"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "payment_processing.handler"          # Entry point in the Lambda code
  runtime       = "python3.8"                           # Assuming you need Python runtime per your script
  filename      = "lambda_files/payment_processing.zip" # Lambda package location
  timeout       = 10
  memory_size   = 256

  # Environment variables for KMS key aliases
  environment {
    variables = {
      ISSUER                   = "payroc"                      # Unique identifier for the payment system
      AUDIENCE                 = "payment-processing-api" # Replace with actual DNS (or) API Gateway URL (or)  the name of the API
      JWT_SIGNING_KEY_ALIAS    = aws_kms_alias.jwt_signing_key_alias.arn
      JWT_ENCRYPTION_KEY_ALIAS = aws_kms_alias.encryption_key_alias.arn
    }
  }
}

# Tokenization and Error Handling Lambda Function
resource "aws_lambda_function" "tokenization_lambda" {
  function_name = "${var.project_name}-TokenizationFunction"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "tokenization.handler"          # Entry point in the Lambda code
  runtime       = "python3.8"                     # Assuming Python runtime
  filename      = "lambda_files/tokenization.zip" # Lambda package location
  timeout       = 10
  memory_size   = 256

  # Environment variables for KMS key aliases
  environment {
    variables = {
      JWT_SIGNING_KEY_ALIAS    = aws_kms_alias.jwt_signing_key_alias.arn
      JWT_ENCRYPTION_KEY_ALIAS = aws_kms_alias.encryption_key_alias.arn
    }
  }
}
