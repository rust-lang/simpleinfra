#!/bin/bash
# Installed by cloud-init and run as root on first boot.
set -euo pipefail
umask 022
export DEBIAN_FRONTEND=noninteractive
export AWS_PAGER=""

# Preserve cloud-init output while also recording bootstrap failures in the
# journal and EC2 console. Keep console/file output if journal delivery fails.
exec > >(tee --output-error=warn /dev/console >(systemd-cat --identifier=docs-rs-builder-bootstrap)) 2>&1

. /etc/os-release
if [ "$ID" != ubuntu ] || [ "$VERSION_ID" != 24.04 ] || [ "$(uname -m)" != x86_64 ]; then
    echo 'Builder bootstrap requires Ubuntu 24.04 amd64' >&2
    exit 1
fi

instance_id=""
workdir=$(mktemp -d /var/tmp/docs-rs-bootstrap.XXXXXX)
cleanup() {
    status=$?
    rm -rf "$workdir"
    if [ "$status" -ne 0 ] && command -v aws >/dev/null 2>&1 && [ -n "$instance_id" ]; then
        aws autoscaling complete-lifecycle-action \
            --auto-scaling-group-name "$(jq -r .asg_name /etc/docs-rs/host.json)" \
            --lifecycle-hook-name "$(jq -r .launch_hook /etc/docs-rs/host.json)" \
            --instance-id "$instance_id" --lifecycle-action-result ABANDON || true
    fi
}
trap cleanup EXIT

# On a manual rerun, stop the previous builder before changing host configuration.
if systemctl cat builder.service >/dev/null 2>&1; then
    systemctl stop builder.service
fi

AWS_REGION=$(jq -r .region /etc/docs-rs/host.json)
export AWS_DEFAULT_REGION="$AWS_REGION"
instance_id=$(cloud-init query v1.instance_id)
prefix=$(jq -r .prefix /etc/docs-rs/host.json)
workspace=$(jq -r .workspace /etc/docs-rs/host.json)

# Like Crater, use the official AWS CLI installer. Instance-role credentials
# are discovered automatically; no static credentials are written to disk.
if ! command -v aws >/dev/null 2>&1; then
    curl --fail --silent --show-error --location --retry 5 \
        https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o "$workdir/aws.zip"
    unzip -q "$workdir/aws.zip" -d "$workdir"
    "$workdir/aws/install"
fi

install -d -m 0755 /etc/docker "$prefix" "$workspace"

# Install the host Agent without passing its API key through installer arguments
# or environment. The installer preserves an existing configuration file.
install -d -m 0755 /etc/datadog-agent
install -m 0600 /dev/null /etc/datadog-agent/datadog.yaml
aws ssm get-parameter --name "$(jq -r .datadog_api_key_parameter /etc/docs-rs/host.json)" \
    --with-decryption --output json \
    | jq --exit-status --raw-output '
        .Parameter.Value |
        if type != "string" or length == 0 or test("[\r\n]")
        then error("Datadog API key must be a nonempty single-line string")
        else "api_key: " + tojson end' > /etc/datadog-agent/datadog.yaml
cat /etc/docs-rs/datadog.yaml >> /etc/datadog-agent/datadog.yaml
curl --fail --silent --show-error --location --retry 5 \
    https://install.datadoghq.com/scripts/install_script_agent7.sh -o "$workdir/install-datadog.sh"
DD_INSTALL_ONLY=true bash "$workdir/install-datadog.sh"
chown root:dd-agent /etc/datadog-agent/datadog.yaml
chmod 0640 /etc/datadog-agent/datadog.yaml
usermod -a -G docker,systemd-journal dd-agent
systemctl enable datadog-agent.service
systemctl restart datadog-agent.service

runsc_version=$(jq -r .runsc_version /etc/docs-rs/host.json)
curl --fail --silent --show-error --location --retry 5 \
    "https://storage.googleapis.com/gvisor/releases/pool/$runsc_version/binary-amd64/runsc.deb" \
    -o "$workdir/runsc.deb"
printf '%s  %s\n' "$(jq -r .runsc_sha256 /etc/docs-rs/host.json)" "$workdir/runsc.deb" | sha256sum --check
apt-get -o DPkg::Lock::Timeout=600 install -y "$workdir/runsc.deb"
systemctl unmask docker.service
systemctl enable docker.service
systemctl restart docker.service

docker run --rm --runtime=runsc --network=none public.ecr.aws/docker/library/alpine:3.22 true

systemctl daemon-reload
systemctl enable builder.service
systemctl restart --no-block builder.service

# The launch hook keeps the host Pending:Wait until its container starts.
# Allow initial image publishing / pulls to take time; the hook times out after 30m.
# EC2 status checks handle host failures later; systemd retries container failures.
for attempt in $(seq 1 240); do
    container_id=$(docker inspect --format '{{if .State.Running}}{{.Id}}{{end}}' docs-rs-builder 2>/dev/null) || container_id=""
    if [ -n "$container_id" ]; then
        sleep 10
        running_id=$(docker inspect --format '{{if .State.Running}}{{.Id}}{{end}}' docs-rs-builder 2>/dev/null) || running_id=""
        if [ "$running_id" = "$container_id" ]; then
            aws autoscaling complete-lifecycle-action \
                --auto-scaling-group-name "$(jq -r .asg_name /etc/docs-rs/host.json)" \
                --lifecycle-hook-name "$(jq -r .launch_hook /etc/docs-rs/host.json)" \
                --instance-id "$instance_id" --lifecycle-action-result CONTINUE
            echo 'Builder container started; ASG launch hook completed'
            exit 0
        fi
    fi
    sleep 5
done
echo 'Builder container did not start successfully before bootstrap timed out' >&2
exit 1
