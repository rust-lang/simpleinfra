#!/bin/bash

set -euo pipefail

mkdir -p /opt
cd /opt
sudo apt update
sudo apt install -y vim jq docker.io unzip

# Install aws cli per instructions (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

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

aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin ${docker_url}

docker pull ${docker_url}

mkdir -p /var/lib/crater-agent-workspace

# Mount the local SSD as the Crater workspace
sudo mkfs.ext4 -F /dev/disk/by-id/google-local-nvme-ssd-0
sudo mount /dev/disk/by-id/google-local-nvme-ssd-0 /var/lib/crater-agent-workspace
sudo chmod a+rwx /var/lib/crater-agent-workspace

curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/update-script \
    -o /opt/update.sh \
    -H "Metadata-Flavor: Google"

chmod +x /opt/update.sh

# Run update task every 5 minutes
sudo systemd-run --unit crater-agent-update --on-calendar='*:0/5' /opt/update.sh

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
        --threads 8
