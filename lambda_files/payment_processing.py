# Retrieve the card data and validate input.
# Encrypt the card data using AWS KMS.
# Create and sign a JWT containing relevant metadata and encrypted card data.

import json
import base64
import os
import boto3
import jwt
from datetime import datetime, timedelta

# Initialize KMS client and environment variables
kms_client = boto3.client('kms')
ISSUER = os.environ['ISSUER']
AUDIENCE = os.environ['AUDIENCE']
JWT_SIGNING_KEY_ALIAS = os.environ['JWT_SIGNING_KEY_ALIAS']
JWT_ENCRYPTION_KEY_ALIAS = os.environ['JWT_ENCRYPTION_KEY_ALIAS']

def encrypt_data(data):
    # Encrypt sensitive data (card details) using AWS KMS
    response = kms_client.encrypt(
        KeyId=JWT_ENCRYPTION_KEY_ALIAS,
        Plaintext=data.encode('utf-8')
    )
    return base64.b64encode(response['CiphertextBlob']).decode('utf-8')

def sign_jwt(payload):
    # Sign JWT with KMS using the specified signing key alias
    now = datetime.utcnow()
    token_payload = {
        "iss": ISSUER,
        "aud": AUDIENCE,
        "iat": now,
        "exp": now + timedelta(minutes=30),
        "data": payload  # The encrypted card data as payload
    }
    signed_token = jwt.encode(token_payload, JWT_SIGNING_KEY_ALIAS, algorithm="RS256")
    return signed_token

def lambda_handler(event, context):
    # Retrieve card details from the request
    body = json.loads(event.get('body', '{}'))
    card_number = body.get('card_number')
    cvv = body.get('cvv')
    expiry_date = body.get('expiry_date')

    # Validate required fields
    if not card_number or not cvv or not expiry_date:
        return {
            'statusCode': 400,
            'body': json.dumps({"error": "Missing required fields"})
        }

    try:
        # Encrypt card details
        sensitive_data = f"{card_number}:{cvv}:{expiry_date}"
        encrypted_data = encrypt_data(sensitive_data)

        # Sign JWT with the encrypted card data as payload
        jwt_token = sign_jwt(encrypted_data)

        return {
            'statusCode': 200,
            'body': json.dumps({
                "jwt_token": jwt_token,
                "message": "Data successfully encrypted and signed."
            })
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({"error": str(e)})
        }
