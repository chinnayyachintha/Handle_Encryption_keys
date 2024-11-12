# Define the main API Gateway
resource "aws_api_gateway_rest_api" "payment_api" {
  name        = "${var.project_name}-api"
  description = "API for payment processing and tokenization"
}

# Payment Processing Resource and Method
resource "aws_api_gateway_resource" "payment_resource" {
  rest_api_id = aws_api_gateway_rest_api.payment_api.id
  parent_id   = aws_api_gateway_rest_api.payment_api.root_resource_id
  path_part   = "payments"
}

resource "aws_api_gateway_method" "payment_method" {
  rest_api_id   = aws_api_gateway_rest_api.payment_api.id
  resource_id   = aws_api_gateway_resource.payment_resource.id
  http_method   = "POST"
  authorization = "NONE" # Replace with Lambda authorizer if needed
}

resource "aws_api_gateway_integration" "payment_integration" {
  rest_api_id             = aws_api_gateway_rest_api.payment_api.id
  resource_id             = aws_api_gateway_resource.payment_resource.id
  http_method             = aws_api_gateway_method.payment_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.payment_processing_lambda.arn}/invocations"
}

# Tokenization Resource and Method
resource "aws_api_gateway_resource" "tokenization_resource" {
  rest_api_id = aws_api_gateway_rest_api.payment_api.id
  parent_id   = aws_api_gateway_rest_api.payment_api.root_resource_id
  path_part   = "tokenization"
}

resource "aws_api_gateway_method" "tokenization_method" {
  rest_api_id   = aws_api_gateway_rest_api.payment_api.id
  resource_id   = aws_api_gateway_resource.tokenization_resource.id
  http_method   = "POST"
  authorization = "NONE" # Replace with Lambda authorizer if needed
}

resource "aws_api_gateway_integration" "tokenization_integration" {
  rest_api_id             = aws_api_gateway_rest_api.payment_api.id
  resource_id             = aws_api_gateway_resource.tokenization_resource.id
  http_method             = aws_api_gateway_method.tokenization_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.tokenization_lambda.arn}/invocations"
}

# Permissions to allow API Gateway to invoke each Lambda function
resource "aws_lambda_permission" "allow_api_gateway_payment" {
  statement_id  = "AllowAPIGatewayInvokePayment"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payment_processing_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.payment_api.execution_arn}/*/POST/payments"
}

resource "aws_lambda_permission" "allow_api_gateway_tokenization" {
  statement_id  = "AllowAPIGatewayInvokeTokenization"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tokenization_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.payment_api.execution_arn}/*/POST/tokenization"
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.payment_integration,
    aws_api_gateway_integration.tokenization_integration,
    aws_lambda_permission.allow_api_gateway_payment,
    aws_lambda_permission.allow_api_gateway_tokenization
  ]
  rest_api_id = aws_api_gateway_rest_api.payment_api.id
  stage_name  = var.stage_name
}