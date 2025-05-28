import boto3
import os
import logging
import json

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
rds = boto3.client('rds')
elb = boto3.client('elbv2')
ec2 = boto3.client('ec2')
autoscaling = boto3.client('autoscaling')
ecs = boto3.client('ecs')

# Environment variables
DB_INSTANCE_IDENTIFIER = os.environ.get('DB_INSTANCE_IDENTIFIER')
JENKINS_ASG_NAME = os.environ.get('JENKINS_ASG_NAME')
MONITORING_ASG_NAME = os.environ.get('MONITORING_ASG_NAME')
ECS_CLUSTER_NAME = os.environ.get('ECS_CLUSTER_NAME')
ECS_SERVICES = os.environ.get('ECS_SERVICES', '').split(',')
TARGET_GROUPS = json.loads(os.environ.get('TARGET_GROUPS', '{}'))

def handler(event, context):
    """Main handler function for DR failover"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    try:
        # Step 1: Promote RDS read replica to standalone instance
        promote_rds_replica()
        
        # Step 2: Scale up ASGs for Jenkins and monitoring
        scale_up_asgs()
        
        # Step 3: Scale up ECS services
        scale_up_ecs_services()
        
        # Step 4: Register targets with load balancers
        register_targets()
        
        return {
            'statusCode': 200,
            'body': json.dumps('DR failover completed successfully')
        }
    except Exception as e:
        logger.error(f"Error during DR failover: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error during DR failover: {str(e)}')
        }

def promote_rds_replica():
    """Promote RDS read replica to standalone instance"""
    if not DB_INSTANCE_IDENTIFIER:
        logger.warning("DB_INSTANCE_IDENTIFIER not provided, skipping RDS promotion")
        return
    
    logger.info(f"Promoting RDS read replica {DB_INSTANCE_IDENTIFIER} to standalone instance")
    
    try:
        # Check if the instance is a read replica
        response = rds.describe_db_instances(DBInstanceIdentifier=DB_INSTANCE_IDENTIFIER)
        db_instance = response['DBInstances'][0]
        
        if not db_instance.get('ReadReplicaSourceDBInstanceIdentifier'):
            logger.warning(f"DB instance {DB_INSTANCE_IDENTIFIER} is not a read replica, skipping promotion")
            return
        
        # Promote the read replica
        rds.promote_read_replica(DBInstanceIdentifier=DB_INSTANCE_IDENTIFIER)
        
        logger.info(f"Successfully initiated promotion of {DB_INSTANCE_IDENTIFIER}")
        
        # Wait for the promotion to complete
        waiter = rds.get_waiter('db_instance_available')
        logger.info(f"Waiting for {DB_INSTANCE_IDENTIFIER} to complete promotion...")
        waiter.wait(DBInstanceIdentifier=DB_INSTANCE_IDENTIFIER)
        
        logger.info(f"RDS instance {DB_INSTANCE_IDENTIFIER} successfully promoted to standalone instance")
    except Exception as e:
        logger.error(f"Error promoting RDS replica: {str(e)}")
        raise

def scale_up_asgs():
    """Scale up Auto Scaling Groups for Jenkins and monitoring"""
    asgs_to_scale = []
    
    if JENKINS_ASG_NAME:
        asgs_to_scale.append({
            'name': JENKINS_ASG_NAME,
            'min': 1,
            'max': 3,
            'desired': 1
        })
    
    if MONITORING_ASG_NAME:
        asgs_to_scale.append({
            'name': MONITORING_ASG_NAME,
            'min': 1,
            'max': 3,
            'desired': 1
        })
    
    if not asgs_to_scale:
        logger.warning("No ASGs configured for scaling, skipping ASG scaling")
        return
    
    for asg in asgs_to_scale:
        try:
            logger.info(f"Scaling ASG {asg['name']} to min={asg['min']}, max={asg['max']}, desired={asg['desired']}")
            
            autoscaling.update_auto_scaling_group(
                AutoScalingGroupName=asg['name'],
                MinSize=asg['min'],
                MaxSize=asg['max'],
                DesiredCapacity=asg['desired']
            )
            
            logger.info(f"Successfully updated ASG {asg['name']}")
        except Exception as e:
            logger.error(f"Error scaling ASG {asg['name']}: {str(e)}")
            raise

def scale_up_ecs_services():
    """Scale up ECS services"""
    if not ECS_CLUSTER_NAME or not ECS_SERVICES:
        logger.warning("ECS_CLUSTER_NAME or ECS_SERVICES not provided, skipping ECS scaling")
        return
    
    for service_name in ECS_SERVICES:
        if not service_name.strip():
            continue
            
        try:
            logger.info(f"Scaling ECS service {service_name} in cluster {ECS_CLUSTER_NAME}")
            
            # Get current service
            response = ecs.describe_services(
                cluster=ECS_CLUSTER_NAME,
                services=[service_name]
            )
            
            if not response['services']:
                logger.warning(f"ECS service {service_name} not found in cluster {ECS_CLUSTER_NAME}")
                continue
                
            # Update service desired count
            ecs.update_service(
                cluster=ECS_CLUSTER_NAME,
                service=service_name,
                desiredCount=1  # Start with at least 1 task
            )
            
            logger.info(f"Successfully scaled ECS service {service_name}")
        except Exception as e:
            logger.error(f"Error scaling ECS service {service_name}: {str(e)}")
            # Continue with other services even if one fails
            continue

def register_targets():
    """Register targets with load balancers"""
    if not TARGET_GROUPS:
        logger.warning("TARGET_GROUPS not provided, skipping target registration")
        return
    
    # Wait for instances to be running and ready
    logger.info("Waiting for instances to be ready before registering with target groups")
    
    # Process each target group
    for target_group_arn, target_config in TARGET_GROUPS.items():
        try:
            target_type = target_config.get('type', 'instance')
            source_asg = target_config.get('source_asg')
            source_ecs = target_config.get('source_ecs')
            
            if target_type == 'instance' and source_asg:
                # Register instances from ASG
                register_asg_instances(source_asg, target_group_arn)
            elif target_type == 'ip' and source_ecs:
                # Register IPs from ECS tasks
                register_ecs_tasks(source_ecs, target_group_arn)
            else:
                logger.warning(f"Unsupported target configuration for {target_group_arn}")
        except Exception as e:
            logger.error(f"Error registering targets for {target_group_arn}: {str(e)}")
            # Continue with other target groups even if one fails
            continue

def register_asg_instances(asg_name, target_group_arn):
    """Register instances from an Auto Scaling Group with a target group"""
    logger.info(f"Registering instances from ASG {asg_name} with target group {target_group_arn}")
    
    try:
        # Get instances from ASG
        response = autoscaling.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        
        if not response['AutoScalingGroups']:
            logger.warning(f"ASG {asg_name} not found")
            return
            
        instances = response['AutoScalingGroups'][0]['Instances']
        instance_ids = [instance['InstanceId'] for instance in instances if instance['LifecycleState'] == 'InService']
        
        if not instance_ids:
            logger.warning(f"No InService instances found in ASG {asg_name}")
            return
        
        # Register instances with target group
        targets = [{'Id': instance_id} for instance_id in instance_ids]
        
        elb.register_targets(
            TargetGroupArn=target_group_arn,
            Targets=targets
        )
        
        logger.info(f"Successfully registered {len(targets)} instances with target group {target_group_arn}")
    except Exception as e:
        logger.error(f"Error registering ASG instances: {str(e)}")
        raise

def register_ecs_tasks(service_info, target_group_arn):
    """Register IPs from ECS tasks with a target group"""
    parts = service_info.split('/')
    if len(parts) != 2:
        logger.error(f"Invalid ECS service info format: {service_info}. Expected format: cluster/service")
        return
        
    cluster_name, service_name = parts
    
    logger.info(f"Registering IPs from ECS service {service_name} in cluster {cluster_name} with target group {target_group_arn}")
    
    try:
        # Get tasks for the service
        response = ecs.list_tasks(
            cluster=cluster_name,
            serviceName=service_name,
            desiredStatus='RUNNING'
        )
        
        task_arns = response.get('taskArns', [])
        
        if not task_arns:
            logger.warning(f"No running tasks found for service {service_name} in cluster {cluster_name}")
            return
            
        # Get task details
        task_details = ecs.describe_tasks(
            cluster=cluster_name,
            tasks=task_arns
        )
        
        # Extract network interfaces
        targets = []
        for task in task_details['tasks']:
            for container in task['containers']:
                for network_interface in container.get('networkInterfaces', []):
                    private_ip = network_interface.get('privateIpv4Address')
                    if private_ip:
                        targets.append({'Id': private_ip, 'Port': 80})  # Assuming port 80, adjust as needed
        
        if not targets:
            logger.warning(f"No valid network interfaces found for tasks in service {service_name}")
            return
            
        # Register IPs with target group
        elb.register_targets(
            TargetGroupArn=target_group_arn,
            Targets=targets
        )
        
        logger.info(f"Successfully registered {len(targets)} IPs with target group {target_group_arn}")
    except Exception as e:
        logger.error(f"Error registering ECS task IPs: {str(e)}")
        raise
