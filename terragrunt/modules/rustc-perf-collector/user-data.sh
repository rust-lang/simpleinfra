#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

# EC2 executes user data as root through cloud-init on the first boot. Install
# both rustc-perf build prerequisites and the perf binary matching the running
# AWS kernel; a generic perf package can point at an incompatible binary.
apt-get update
apt-get install --yes \
  build-essential \
  cmake \
  git \
  libssl-dev \
  "linux-tools-$(uname -r)" \
  pkg-config \
  python3-venv \
  unzip

tee /etc/sysctl.d/90-rustc-perf.conf >/dev/null <<'EOF'
# Allow the unprivileged collector process to use all PMU events.
kernel.perf_event_paranoid = -1
# Symbol addresses are useful when correlating counter samples with profiles.
kernel.kptr_restrict = 0
EOF

sysctl --system

# Canonical's AWS images ship the agent as a snap. Keep this fallback for an
# image where it is not preinstalled yet.
if ! snap list amazon-ssm-agent >/dev/null 2>&1; then
  snap install amazon-ssm-agent --classic
fi
systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service

install -d -m 0755 /var/lib/rustc-perf
# Fail cloud-init if EC2 does not expose the core PMU events rustc-perf relies
# on to this M9g guest. Dedicated Host tenancy reserves the physical server,
# but this runtime check is what verifies the counters are actually usable.
# The marker distinguishes verified bootstrap from a merely running instance.
perf stat \
  --event cycles,instructions,branches,branch-misses \
  -- sleep 1
date --iso-8601=seconds > /var/lib/rustc-perf/perf-counters-ready
