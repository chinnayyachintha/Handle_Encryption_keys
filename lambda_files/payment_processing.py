# Logic for paymentProcessingLambda:
# Verify JWT: Check the token’s issuer (iss), audience (aud), issue time (iat), and expiration (exp).
# Decrypt Payload: Decrypt sensitive data encrypted with KMS.
# Process Payment: Simulate payment processing after successful JWT verification.

import os
import jwt
import boto3
from botocore.exceptions import ClientError
from datetime import datetime

kms_client = boto3.client('kms')

# Environment Variables
ISSUER = os.getenv("ISSUER")
AUDIENCE = os.getenv("AUDIENCE")
JWT_SIGNING_KEY_ALIAS = os.getenv("JWT_SIGNING_KEY_ALIAS")
JWT_ENCRYPTION_KEY_ALIAS = os.getenv("JWT_ENCRYPTION_KEY_ALIAS")

def verify_jwt(token):
    try:
        decoded_token = jwt.decode(
            token,
            key="your-public-key",  # Replace with actual public key from KMS
            algorithms=["RS256"],
            audience=AUDIENCE,
            issuer=ISSUER
        )
        return decoded_token
    except jwt.ExpiredSignatureError:
        raise ValueError("Token expired")
    except jwt.InvalidAudienceError:
        raise ValueError("Invalid audience")
    except jwt.InvalidIssuerError:
        raise ValueError("Invalid issuer")
    except Exception as e:
        raise ValueError(f"JWT verification failed: {str(e)}")

def decrypt_data(ciphertext):
    try:
        response = kms_client.decrypt(
            CiphertextBlob=bytes(ciphertext, 'utf-8'),
            KeyId=JWT_ENCRYPTION_KEY_ALIAS
        )
        return response['Plaintext'].decode('utf-8')
    except ClientError as e:
        raise ValueError(f"Decryption failed: {e}")

def handler(event, context):
    token = event.get("jwt_token")
    encrypted_data = event.get("encrypted_data")
    
    # Verify JWT
    try:
        verified_jwt = verify_jwt(token)
    except ValueError as e:
        return {"status": "error", "message": str(e)}
    
    # Decrypt Data
    try:
        decrypted_data = decrypt_data(encrypted_data)
    except ValueError as e:
        return {"status": "error", "message": str(e)}
    
    # Process Payment Logic (mocked)
    # Assume successful payment
    return {"status": "success", "message": "Payment processed successfully"}
