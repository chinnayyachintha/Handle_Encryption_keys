# Logic for tokenizationLambda:
# Tokenization: Generate a secure token for sensitive data.
# Validation: Ensure input data is in the correct format.
# Error Handling and Logging: Capture errors, log securely without sensitive data, and return error messages for invalid inputs.

import os
import boto3
import logging
import re
from botocore.exceptions import ClientError

# Initialize AWS services
kms_client = boto3.client('kms')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment Variables
TOKENIZATION_KEY_ALIAS = os.getenv("JWT_SIGNING_KEY_ALIAS")

def validate_payment_data(data):
    errors = []
    if not data.get("card_number") or len(data["card_number"]) != 16 or not re.match(r"^\d{16}$", data["card_number"]):
        errors.append("Invalid card number format")
    if not data.get("cvv") or not re.match(r"^\d{3}$", data["cvv"]):
        errors.append("Invalid CVV format")
    if errors:
        return {"status": "error", "errors": errors}
    return {"status": "success"}

def generate_token(data):
    try:
        response = kms_client.encrypt(
            KeyId=TOKENIZATION_KEY_ALIAS,
            Plaintext=data
        )
        token = response['CiphertextBlob'].hex()
        return token
    except ClientError as e:
        logger.error("Tokenization error", exc_info=True)
        return {"status": "error", "message": "Tokenization failed"}

def handler(event, context):
    payment_data = event.get("payment_data")
    
    # Validate Data
    validation_result = validate_payment_data(payment_data)
    if validation_result["status"] == "error":
        logger.warning("Validation failed", extra={"errors": validation_result["errors"]})
        return validation_result

    # Generate Token
    token = generate_token(payment_data.get("card_number"))
    if token.get("status") == "error":
        return token

    return {"status": "success", "token": token}
