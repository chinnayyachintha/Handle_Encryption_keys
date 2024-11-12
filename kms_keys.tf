# KMS Key for Signing and Encryption

# KMS Key for JWT Signing
resource "aws_kms_key" "jwt_signing_key" {
  description              = "KMS key for signing JWTs"
  key_usage                = "SIGN_VERIFY" # For RSA signing only
  customer_master_key_spec = "RSA_2048"    # RSA key for JWT signature verification

  tags = {
    Name = "${var.project_name}-JWTSigningKey"
  }
}

# Alias for the JWT Signing Key
resource "aws_kms_alias" "jwt_signing_key_alias" {
  name          = "alias/jwtSigningKey"
  target_key_id = aws_kms_key.jwt_signing_key.id
}

# KMS Key for Card Data Encryption
resource "aws_kms_key" "encryption_key" {
  description              = "KMS key for encrypting sensitive cardholder data"
  key_usage                = "ENCRYPT_DECRYPT"   # For encrypting/decrypting card data
  customer_master_key_spec = "SYMMETRIC_DEFAULT" # Symmetric encryption for better performance

  tags = {
    Name = "${var.project_name}-EncryptionKey"
  }
}

# Alias for the Encryption Key
resource "aws_kms_alias" "encryption_key_alias" {
  name          = "alias/encryptionKey"
  target_key_id = aws_kms_key.encryption_key.id
}
