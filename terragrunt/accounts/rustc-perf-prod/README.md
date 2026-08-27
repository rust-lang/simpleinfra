# rustc-perf production AWS account

This account contains the Graviton 5 collector for rustc-perf. The collector is
an `m9g.12xlarge` partition, with 48 vCPUs and 192 GiB of memory, placed on an
M9g Dedicated Host in `us-east-2`. The host is allocated for the M9g family,
not the 12xlarge size. AWS's capacity table currently lists room for eight
`m9g.12xlarge` instances on an empty host, so this initial collector leaves
capacity for more compatible M9g instances later. Dedicated tenancy keeps the
physical server exclusive to the account; a boot-time `perf stat` smoke test
separately verifies that the guest exposes the hardware counters rustc-perf
needs.

The machine has no inbound firewall rules. Operators connect through AWS
Systems Manager Session Manager. Its public IPv4 address is used only for
outbound access without the cost of a NAT gateway.

Terraform allocates the host with On-Demand billing. It does not purchase a
one- or three-year Dedicated Host Reservation: selecting an offering and its
payment terms is a separate financial commitment that should be made after the
host exists and the funding terms are confirmed.

## Rollout

Apply the states in this order. Do not apply the collector state until AWS has
approved the quota request.

1. Apply the organization state from the `rust-root` account:

   ```console
   cd terragrunt/accounts/root/aws-organization
   terragrunt plan
   terragrunt apply
   ```

2. Add an AWS CLI profile for the new account, using the account ID shown in
   the IAM Identity Center portal:

   ```ini
   [profile rustc-perf-prod]
   sso_start_url = https://rust-lang.awsapps.com/start
   sso_account_id = <rustc-perf-prod-account-id>
   sso_role_name = AdministratorAccess
   sso_region = us-east-1
   region = us-east-2
   ```

3. Log in and apply the account baseline and quota request:

   ```console
   aws sso login --profile rustc-perf-prod

   cd terragrunt/accounts/rustc-perf-prod/datadog-aws
   terragrunt apply

   cd ../wiz
   terragrunt apply

   cd ../ec2-quota
   terragrunt apply
   ```

4. Wait for the regional Running Dedicated m9g Hosts quota to reach 1. New AWS
   accounts default to zero, and host allocation cannot begin until AWS
   approves the request:

   ```console
   aws service-quotas get-service-quota \
     --profile rustc-perf-prod \
     --region us-east-2 \
     --service-code ec2 \
     --quota-code L-9F9F275C \
     --query 'Quota.Value'
   ```

5. Apply the collector state:

   ```console
   cd terragrunt/accounts/rustc-perf-prod/collector
   terragrunt plan
   terragrunt apply
   ```

## Verify the collector

Once the instance is registered with Systems Manager, start a session:

```console
cd terragrunt/accounts/rustc-perf-prod/collector
instance_id="$(terragrunt output -raw instance_id)"
aws ssm start-session \
  --profile rustc-perf-prod \
  --region us-east-2 \
  --target "$instance_id"
```

On the instance, wait for cloud-init and confirm the PMU smoke test succeeded:

```console
cloud-init status --wait
test -f /var/lib/rustc-perf/perf-counters-ready
perf stat -e cycles,instructions,branches,branch-misses -- sleep 1
```

The boot configuration installs the native kernel's `perf` package and sets
`kernel.perf_event_paranoid=-1`, allowing the unprivileged collector process to
read the counters. Stopping the instance preserves its encrypted root volume,
but it does **not** stop billing for the allocated Dedicated Host. Ending host
charges requires terminating every instance on the host and releasing the host;
the collector's API termination protection makes that an explicit Terraform
configuration change rather than an accidental command.

## Dedicated host auto recovery

[Dedicated Host auto recovery](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/dedicated-hosts-recovery.html)
is disabled because AWS does not currently list
M9g among the instance families that support it.
