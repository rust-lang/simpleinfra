#!/bin/bash
# Called by builder.service on every container start. Never enable shell tracing.
set -euo pipefail
umask 077
export AWS_PAGER=""
# Expose setup failures through EC2's system log before container logging exists.
# Save the service's journal descriptors for the foreground container below.
exec 3>&1 4>&2
exec > /dev/console 2>&1
config=/etc/docs-rs/host.json
export AWS_DEFAULT_REGION
AWS_DEFAULT_REGION=$(jq -r .region "$config")
export DOCKER_CONFIG=/run/docs-rs/docker
mkdir -p "$DOCKER_CONFIG"

env_file=$(mktemp /run/docs-rs/builder.env.XXXXXX)
trap 'rm -f "$env_file"' EXIT
jq -r '.environment | to_entries[] | "\(.key)=\(.value)"' "$config" > "$env_file"
while IFS=$'\t' read -r name parameter; do
    printf '%s=' "$name" >> "$env_file"
    aws ssm get-parameter --name "$parameter" --with-decryption \
        --query Parameter.Value --output json \
        | jq --exit-status --raw-output '
            if type != "string" or length == 0 or test("[\r\n]")
            then error("Builder secrets must be nonempty single-line strings")
            else . end' >> "$env_file"
done < <(jq -r '.secrets | to_entries[] | [.key, .value] | @tsv' "$config")
mv "$env_file" /run/docs-rs/builder.env

image=$(jq -r .image "$config")
registry=$(printf '%s' "$image" | cut -d / -f 1)
aws ecr get-login-password | docker login --username AWS --password-stdin "$registry"
docker pull "$image"
# Remove only this service's stale container, never crate-build siblings.
docker container rm --force docs-rs-builder >/dev/null 2>&1 || true

# Application output stays in the journal and CloudWatch, off the EC2 console.
exec 1>&3 2>&4 3>&- 4>&-
exec docker run --rm --name docs-rs-builder --network host \
    --stop-timeout 120 \
    --env-file /run/docs-rs/builder.env \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(jq -r .prefix "$config"):$(jq -r .prefix "$config")" \
    --volume "$(jq -r .workspace "$config"):$(jq -r .workspace "$config")" \
    --log-driver awslogs \
    --log-opt "awslogs-region=$AWS_DEFAULT_REGION" \
    --log-opt "awslogs-group=$(jq -r .log_group "$config")" \
    --log-opt "awslogs-stream=$(cat /etc/docs-rs/instance-id)" \
    "$image" start
