# Store the KMS Key ID in Secrets Manager

# Store the JWT Signing KMS Key ID in Secrets Manager
resource "aws_secretsmanager_secret" "jwt_signing_key_secret" {
  name        = "${var.project_name}-JWTSigningKMSKeyID"
  description = "Stores the KMS Key ID for JWT Signing in Payment Processing"
}

resource "aws_secretsmanager_secret_version" "jwt_signing_key_secret_version" {
  secret_id = aws_secretsmanager_secret.jwt_signing_key_secret.id
  secret_string = jsonencode({
    "jwt_signing_kms_key_id" = aws_kms_key.jwt_signing_key.key_id
  })
}

# Store the Encryption KMS Key ID in Secrets Manager
resource "aws_secretsmanager_secret" "encryption_key_secret" {
  name        = "${var.project_name}-EncryptionKMSKeyID"
  description = "Stores the KMS Key ID for Card Data Encryption in Payment Processing"
}

resource "aws_secretsmanager_secret_version" "encryption_key_secret_version" {
  secret_id = aws_secretsmanager_secret.encryption_key_secret.id
  secret_string = jsonencode({
    "encryption_kms_key_id" = aws_kms_key.encryption_key.key_id
  })
}
