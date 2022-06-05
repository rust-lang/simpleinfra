#!/bin/bash

set -euo pipefail

mkdir -p /opt
cd /opt
sudo apt update
sudo apt install -y vim jq docker.io awscli

sudo systemctl unmask docker.service
sudo systemctl start docker.service

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

docker pull ${docker_url}

mkdir -p /var/lib/crater-agent-workspace

systemd-run \
    --unit crater-agent \
    docker run --init --rm --name crater-agent \
        -v /var/lib/crater-agent-workspace:/workspace \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e RUST_LOG=crater=trace,rustwide=info \
        -p 4343:4343 \
        ${docker_url} \
        agent https://crater.rust-lang.org \
        $AGENT_TOKEN \
        --threads 5
