#!/bin/bash

set -euo pipefail

aws sts assume-role-with-web-identity \
    --role-arn ${role} \
    --role-session-name $(hostname) \
    --duration-seconds 900 \
    --web-identity-token $(curl \
        -H "Metadata-Flavor: Google" \
        'http://metadata/computeMetadata/v1/instance/service-accounts/default/identity?audience=aws') \
> credentials

export AWS_ACCESS_KEY_ID="$(jq -r .Credentials.AccessKeyId credentials)"
export AWS_SECRET_ACCESS_KEY="$(jq -r .Credentials.SecretAccessKey credentials)"
export AWS_SESSION_TOKEN="$(jq -r .Credentials.SessionToken credentials)"

rm credentials # Remove the raw file on disk, no need for that to exist

AGENT_TOKEN=$(aws --region us-west-1 \
    --output text --query Parameter.Value \
    ssm get-parameter \
    --name /prod/ansible/crater-gcp-2/crater-token \
    --with-decryption)

eval $(aws ecr get-login --no-include-email --region us-west-1)

old_id="$(docker images --format "{{.ID}}" "${docker_url}")"
docker pull "${docker_url}"
new_id="$(docker images --format "{{.ID}}" "${docker_url}")"

if [[ "$old_id" != "$new_id" ]]; then
    echo "restarting container..."
    sudo systemctl restart crater-agent
fi
