import json
import os
import boto3
from decimal import Decimal

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("visitor-counter")
client = boto3.client("sns")


def lambda_handler(event, context):
    try:
        # Get current count (0 if the item doesn't exist yet)
        response = table.get_item(Key={"id": "site-counter"})

        # Handle Decimal from DynamoDB
        item = response.get("Item", {})
        current_count = (
            int(item.get("visit_count", 0))
            if isinstance(item.get("visit_count", 0), (int, float, Decimal))
            else 0
        )
        new_count = current_count + 1
        threshold = int(os.environ.get("VISITOR_THRESHOLD", 100))
        if new_count >= threshold:
            sns_topic_arn = os.environ.get("SNS_TOPIC_ARN")
            if sns_topic_arn:
                client.publish(
                    TopicArn=sns_topic_arn,
                    Subject="Cloud Resume - Visitor Count over 100",
                    Message=f"Your Cloud Resume site has been visited {new_count} times!",
                )

        # Update the count in DynamoDB
        table.update_item(
            Key={"id": "site-counter"},
            UpdateExpression="SET visit_count = :val",
            ExpressionAttributeValues={":val": new_count},
        )

        # 3. Return the new count with CORS headers
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": json.dumps({"count": new_count}),
        }
    except Exception as e:
        # Send SNS alert on DynamoDB error
        sns_topic_arn = os.environ.get("SNS_TOPIC_ARN")
        if sns_topic_arn:
            client.publish(
                TopicArn=sns_topic_arn,
                Subject="Cloud Resume - DynamoDB Error",
                Message=f"Error updating visitor counter: {str(e)}",
            )
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": json.dumps({"error": "Failed to update visitor counter"}),
        }
