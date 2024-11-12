# DynamoDB for Tokenization

resource "aws_dynamodb_table" "tokenization_table" {
  name         = "${var.project_name}-TokenizationTable"
  hash_key     = "token_id"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "token_id"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-TokenizationTable"
  }
}
