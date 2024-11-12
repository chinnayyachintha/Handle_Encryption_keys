output "api_gateway_rest_api_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.payment_api.id
}

output "api_gateway_deployment_id" {
  description = "ID of the API Gateway deployment"
  value       = aws_api_gateway_deployment.api_deployment.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for tokenization"
  value       = aws_dynamodb_table.tokenization_table.name
}

output "lambda_execution_role_arn" {
  description = "ARN of the IAM role for Lambda execution"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_policy_arn" {
  description = "ARN of the IAM policy for Lambda access"
  value       = aws_iam_policy.lambda_policy.arn
}

output "jwt_signing_key_arn" {
  description = "ARN of the KMS key for JWT signing"
  value       = aws_kms_key.jwt_signing_key.arn
}

output "encryption_key_arn" {
  description = "ARN of the KMS key for card data encryption"
  value       = aws_kms_key.encryption_key.arn
}

output "payment_processing_lambda_arn" {
  description = "ARN of the payment processing Lambda function"
  value       = aws_lambda_function.payment_processing_lambda.arn
}

output "tokenization_lambda_arn" {
  description = "ARN of the tokenization Lambda function"
  value       = aws_lambda_function.tokenization_lambda.arn
}

output "jwt_signing_key_secret_arn" {
  description = "ARN of the Secrets Manager secret for JWT signing KMS key ID"
  value       = aws_secretsmanager_secret.jwt_signing_key_secret.arn
}

output "encryption_key_secret_arn" {
  description = "ARN of the Secrets Manager secret for encryption KMS key ID"
  value       = aws_secretsmanager_secret.encryption_key_secret.arn
}

output "api_gateway_url" {
  value       = "https://${aws_api_gateway_rest_api.payment_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}/"
  description = "The URL for the API Gateway with the specified stage"
}

output "jwt_signing_key_id" {
  description = "ID of the KMS key for JWT signing"
  value       = aws_kms_key.jwt_signing_key.key_id
}

output "encryption_key_id" {
  description = "ID of the KMS key for card data encryption"
  value       = aws_kms_key.encryption_key.key_id
}