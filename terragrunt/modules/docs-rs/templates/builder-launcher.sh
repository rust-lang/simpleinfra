#!/bin/bash
# Called by builder.service on every container start. Never enable shell tracing.
set -euo pipefail
umask 077
export AWS_PAGER=""
# Keep setup output in the service journal and EC2's system log, even before
# Datadog or container logging is available.
# Save the service's journal descriptors for the foreground container below.
exec 3>&1 4>&2
exec > >(tee --output-error=warn /dev/console) 2>&1
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

# Application output goes to the service journal for Datadog, off the EC2 console.
exec 1>&3 2>&4 3>&- 4>&-
# Rustwide gets sandbox host PIDs from Docker inspect. --pid=host exposes their
# /proc/<pid>/cgroup files; --cgroupns=host keeps those paths relative to the host
# cgroup root. The read-only /sys/fs/cgroup mount exposes memory.peak and
# memory.events (OOM counters), which gVisor does not expose inside sandboxes.
# Only this trusted controller gets host visibility; crate sandboxes stay isolated.
exec docker run --rm --name docs-rs-builder --network host \
    --pid=host --cgroupns=host \
    --stop-timeout 120 \
    --env-file /run/docs-rs/builder.env \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --volume "$(jq -r .prefix "$config"):$(jq -r .prefix "$config")" \
    --volume "$(jq -r .workspace "$config"):$(jq -r .workspace "$config")" \
    "$image" start
