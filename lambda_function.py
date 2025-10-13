import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('be_dynamodb')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError

def lambda_handler(event, context):
    response = table.update_item(
        Key={'id': 'visitors'},
        UpdateExpression='ADD visitorCount :incr',
        ExpressionAttributeValues={':incr': 1},
        ReturnValues='UPDATED_NEW'
    )
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'  # Allow CORS
        },
        'body': json.dumps({'count': response['Attributes']['visitorCount']}, default=decimal_default)
    }

