#!/bin/bash

# This script runs an ECS task.
# The arguments for the script are:
# 1. The cluster name
# 2. The task name
# 3. The name of the container
# 4. The names of the security groups to use as a comma separated list (with no spaces)
# 5. The command to run
#
# For example:
# 
# 	$ ./run-task.sh docs-rs-staging docs-rs-web app docs-rs-staging-service,docs-rs-web '/usr/local/bin/cratesfyi database migrate'

clusterArn=$(aws ecs describe-clusters --clusters $1 | jq -r '.clusters[0].clusterArn')
taskArn=$(aws ecs describe-task-definition --task-definition $2 | jq -r '.taskDefinition.taskDefinitionArn')
subnet=$(aws ec2 describe-subnets | jq -r '.Subnets | .[] | select (.Tags != null and any(.Tags; any(.Key=="Name" and (.Value | contains("public"))))) | .SubnetId' | head -n 1)
cmd=$(echo "\"$5\"" | jq -c 'split(" ")')
sgNames=$(echo "\"$4\"" | jq -c 'split(",")' )
sgs=$(aws ec2 describe-security-groups | jq -r ".SecurityGroups | .[] | select(.GroupName == $sgNames[]) | .GroupId" | paste -sd "," -)

aws ecs run-task \
	--task-definition $taskArn \
	--network-configuration "awsvpcConfiguration={subnets=[$subnet],securityGroups=[$sgs],assignPublicIp=ENABLED}" \
	--launch-type="FARGATE" \
	--cluster $clusterArn \
	--overrides "{\"containerOverrides\": [{\"name\":\"$3\", \"command\": $cmd}]}"
