import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('visitor-counter')

def lambda_handler(event, context):
    # 1. Get current count (0 if the item doesn't exist yet)
    response = table.get_item(
        Key={'id': 'site-counter'}
    )

    # Handle Decimal from DynamoDB safely
    item = response.get('Item', {})
    current_count = int(item.get('visit_count', 0)) if isinstance(item.get('visit_count', 0), (int, float, Decimal)) else 0
    new_count = current_count + 1

    # 2. Update the count in DynamoDB
    table.update_item(
        Key={'id': 'site-counter'},
        UpdateExpression='SET visit_count = :val',
        ExpressionAttributeValues={':val': new_count}
    )

    # 3. Return the new count with CORS headers
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        # new_count is now a plain int, safe for json.dumps
        "body": json.dumps({"count": new_count})
    }
