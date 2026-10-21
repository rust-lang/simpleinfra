# docs.rs EC2 builders

Builders run as Docker containers managed by systemd on dedicated Ubuntu 24.04
amd64 EC2 hosts. Terraform creates an Auto Scaling group (ASG), a Launch Template,
and gzip-compressed first-boot user data. Builders do not use ECS or Ansible.
Web, watcher, and admin workloads continue using ECS/Fargate.

## Configuration and scaling

`builder_count` sets the ASG's minimum, maximum, and desired capacity. All hosts
use `builder_config` for the instance type, EBS settings, and build limits. They
use the first shared subnet and receive public IPs for outbound internet access.
The security group has no inbound rules, including SSH. No interactive host-access
method or automatic workload scaling policy is configured.

Hosts keep their AMI-provided hostnames and have instance identities rather than
stable numbered names or DNS records. Outputs expose `builder_autoscaling_group_name`,
`builder_launch_template_id`, `builder_launch_template_version`, and
`builder_repository_url`.

The ASG replaces hosts that fail EC2 health checks. A launch lifecycle hook keeps
new hosts in `Pending:Wait` until bootstrap sees the builder container running
for two checks ten seconds apart. This confirms startup, not a successful crate
build. A failed bootstrap abandons the launch; the hook also times out after
30 minutes if bootstrap cannot report a result. Systemd retries container failures
once the host is running; EC2 health checks do not detect every application failure.

The account configurations currently request:

| Account | Hosts | Instance type | Build CPU limit | Default build memory | Root EBS |
| --- | --- | --- | --- | --- | --- |
| Staging | 2 | `c8i.xlarge` (4 vCPU, 8 GiB) | 3 | `6GiB` | 64 GiB gp3, 3,000 IOPS, 125 MiB/s |
| Production | 2 | `c8i.4xlarge` (16 vCPU, 32 GiB) | 12 | `6GiB` | 64 GiB gp3, 8,000 IOPS, 1,000 MiB/s |

Per-crate memory exceptions can exceed the default build limit. Changing
`builder_count` changes fleet capacity; it is not driven by queue length.

## First boot and secrets

Terraform manages `/docs-rs/database-url`. The existing SecureString parameter
`/docs-rs/github-access-token` must exist in each account and contain a valid GitHub
token; it is shared with the registry watcher. Terraform reads its ARN without
requesting decryption.

Cloud-init installs Ubuntu packages and writes the configuration, scripts, and
systemd units. Docker configuration and executable files are written after package
installation. The bootstrap script installs the AWS CLI and checksum-pinned
gVisor, restarts Docker, and runs a sandbox smoke test with networking disabled.
The smoke-test image is pulled over the host network. It then enables and starts
`builder.service` and waits for the controller container before completing the
launch hook.

There is no ECS agent, Ubuntu Pro activation, custom kernel mitigation setup,
unattended-upgrade configuration, or daily cleanup timer. OS maintenance depends
on the selected AMI and host replacement. Daily AMI builds and automatic periodic
host recycling are not configured.

Terraform renders non-secret configuration, the selected image, and SSM parameter
names into `/etc/docs-rs/host.json`. `builder.service` runs
`/usr/local/sbin/docs-rs-builder`. On every service start the launcher:

1. Fetches the database URL and GitHub token from SSM with the instance role.
2. Writes non-secret settings and secret values to a root-only
   `/run/docs-rs/builder.env`, rejecting empty or multiline secret values.
3. Authenticates to ECR and pulls the configured image. ECR credentials are stored
   under the root-only `/run/docs-rs/docker` directory.
4. Runs one container named `docs-rs-builder`, using that environment file and
   the host Docker socket and workspace mounts.

The systemd runtime directory is removed after the service stops. Secrets are
not embedded in user data, command arguments, or Terraform state by this launcher.
Container environment values remain accessible to administrators with Docker
access. Secret rotations take effect on service restart or host replacement.

The instance role grants SSM access to only the database and GitHub token
parameters, ECR pull, S3 access to the docs.rs bucket, log-stream writes, and
completion of its ASG's launch hook. No cross-account role assumption is needed.

## Runtime and isolation

The trusted builder uses host networking so AWS SDKs can obtain the instance
profile credentials through IMDSv2 with a response hop limit of 1. It starts
sibling crate-build containers through the host Docker socket, using gVisor
(`runsc`) and networking disabled. Do not expose the Docker socket or enable host
networking for those untrusted build containers.

`build_cpu_limit` and `build_memory_limit` apply to crate-build sandboxes; memory
accepts strings such as `6GiB`. The controller container uses Docker defaults,
with no explicit CPU or memory limits. Docker socket access gives the trusted
controller control of the host's containers; dedicate the hosts to builders.

Application logs use Docker's `awslogs` driver. The existing CloudWatch group
`/ecs/docs-rs-builder` is retained, with a stream per EC2 instance and seven-day
retention. Launcher setup output, including ECR login and image-pull failures,
goes to the EC2 console and is available through **Get system log**. Container
output uses the service journal and CloudWatch without being copied to the console.
Host metrics, system-log forwarding, and Datadog are not configured.

## Deployment and replacement

Publish the docs.rs `build-server` image to the `docs-rs-build-server` ECR
repository. Prefer a commit SHA tag or digest in `builder_image_version`; the
initial default is `latest`. The repository must exist before publishing. On an
initial apply, hosts may wait or fail and retry until the first image is available.
Terraform does not wait for the initial fleet's bootstrap
(`wait_for_capacity_timeout = "0"`), so verify its state explicitly.

Terraform owns the Launch Template configuration and its selected image version.
To deploy a pinned image, update `builder_image_version` in the environment's
Terragrunt inputs and apply the docs.rs unit. Terraform creates a new numeric
Launch Template version, points the ASG to it, and starts an instance refresh.
Changes to embedded startup or launcher scripts, systemd units, Docker settings,
environment configuration, instance type, or EBS settings also create a new
template version and trigger a refresh on apply. The AMI lookup selects the newest
matching Canonical Ubuntu image during Terraform runs; a newly selected AMI also
triggers replacement. User data is marked sensitive to hide its contents in plans.
The refresh continues asynchronously after apply. Keep the version in
infrastructure configuration so later applies do not revert an out-of-band
image change.

Refresh preferences are `MinHealthyPercentage=0` and `MaxHealthyPercentage=100`:
old capacity is terminated before replacement capacity is launched, and the
whole fleet may temporarily stop. Builds interrupted by termination are retried
by the next builder, according to the application's queue recovery behavior.
There is no graceful draining requirement in this initial version.

To recycle hosts on the current template, for example after publishing `latest`,
CI or an operator can run (staging example):

```sh
aws autoscaling start-instance-refresh \
  --profile docs-rs-staging --region us-east-1 \
  --auto-scaling-group-name docs-rs-builders \
  --preferences '{"MinHealthyPercentage":0,"MaxHealthyPercentage":100,"InstanceWarmup":120,"SkipMatching":false}'

aws autoscaling describe-instance-refreshes \
  --profile docs-rs-staging --region us-east-1 \
  --auto-scaling-group-name docs-rs-builders
```

The GitHub deployment role can start and inspect refreshes and publish builder
images. The docs.rs staging workflow publishes SHA and `latest` image tags, then
starts a refresh after release commands and the watcher rollout succeed. It does
not wait for the refresh to finish. `SkipMatching=false` ensures hosts are replaced
even when the template still references the same `latest` tag. A successful CI step
confirms only that AWS accepted the refresh.

The deployment role cannot edit Launch Templates. Selecting a different pinned
image requires the infrastructure apply above. No builder ECS deploy step is needed.

Replacing hosts discards their local data. The initial setup uses one root EBS
filesystem, defaulting to 64 GiB, for Ubuntu, Docker, and builds. There is no
loopback filesystem, separate data volume, or local NVMe storage. Monitor free
space and increase `builder_config.volume_size` when needed.

Host directories are bind-mounted at identical paths inside the controller:

- `/opt/docs-rs/prefix`: builder state.
- `/opt/docs-rs/workspace`: Rustwide toolchains, caches, sources, and builds.

These survive container restart and ordinary reboot, but not instance termination.
There is no scheduled Docker pruning; replacing instances discards accumulated
containers, images, and caches. Automatic periodic recycling is not configured.

## Troubleshooting and staging verification

For bootstrap and launcher setup output, use **EC2 → Instances → Actions → Monitor
and troubleshoot → Get system log**, or retrieve it without host access:

```sh
aws ec2 get-console-output \
  --profile docs-rs-staging --region us-east-1 \
  --instance-id i-REPLACE_ME --latest --query Output --output text
```

A missing CloudWatch stream does not prove cloud-init failed: the stream is created
when Docker starts the builder container. Check console output for package,
SSM, ECR login, and image-pull errors first. Confirm `docs-rs-build-server:latest`
(or the configured pinned version) has been published. An instance in
`Pending:Wait` has not completed the bootstrap readiness check. Launcher setup
output goes to the console; after Docker starts, application output goes to the
journal and CloudWatch. Secrets are fetched again on every controller restart;
a changed token also requires restarting the watcher to reload its copy.

Inspect the ASG and refresh status, confirm launch hooks complete, and run a crate
build with artifacts uploaded to S3. Terminate a host during a build and verify
its replacement retries the unfinished job. Confirm sandbox networking is disabled,
instance-role credentials and SSM reads work, and application logs reach CloudWatch.

With an administrative session available, these host-local commands are useful:

```sh
sudo cloud-init status --long
sudo tail -n 100 /var/log/cloud-init-output.log
sudo systemctl status docker.service builder.service
sudo journalctl -u builder.service -n 100
sudo docker ps
df -h /
```

This initial version provides no SSH or alternative interactive access; the
host-local commands above require a separately arranged administrative session.
Verify a complete build, instance refresh, and queue recovery in staging before
production rollout.
