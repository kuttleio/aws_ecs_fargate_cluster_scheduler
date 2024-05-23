import boto3
import os
import json

ecs_cluster = os.environ["ECS_CLUSTER"]

def update_ecs_service(ecs_cluster, ecs_service, desired_count):
    ecs = boto3.client('ecs')
    update_service = ecs.update_service(
        cluster=ecs_cluster,
        service=ecs_service,
        desiredCount=desired_count,
    )
    print('Service updated:', ecs_service)

def lambda_handler(event, context):
    ecs = boto3.client('ecs')
    action = event.get('action')
    desired_count = 1 if action == "turn-on" else 0

    print(f'{action.capitalize()} cluster:', ecs_cluster)
    
    services = ecs.list_services(
        cluster=ecs_cluster,
        maxResults=50,
    )

    for service in services.get('serviceArns'):
        print(f'{action.capitalize()} service:', service[43:])
        update_ecs_service(ecs_cluster, service, desired_count)

    return {
        'statusCode': 200,
        'body': json.dumps('Cluster switch action completed successfully')
    }
