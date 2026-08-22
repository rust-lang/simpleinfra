packer {
  required_plugins {
    amazon = {
      version = ">= 1.8.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_name" {
  type = string
}

variable "runner_url" {
  type = string
}

variable "architecture" {
  type = string
}

source "amazon-ebs" "ubuntu" {
  ami_name = "${var.ami_name}"

  instance_type = var.architecture == "x86_64" ? "c8a.medium" : "c9g.medium"
  region        = "us-east-2"

  temporary_security_group_source_public_ip = true
  ssh_clear_authorized_keys                 = true

  source_ami_filter {
    filters = {
      name                = var.architecture == "x86_64" ? "ubuntu-minimal/*ubuntu-resolute-26.04-amd64-minimal-*" : "ubuntu-minimal/*ubuntu-resolute-26.04-arm64-minimal-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  ssh_username = "ubuntu"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
}

build {
  name = "learn-packer"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "file" {
    content     = ""
    destination = "/etc/containers/nodocker"
  }

  provisioner "file" {
    # Without this we end up hitting the tiny default pids limit on larger hosts.
    content     = <<EOF
[content]
pids_limit=1000000
default_ulimits=["nofile=100000:100000"]
EOF
    destination = "/tmp/containers.conf"
  }

  provisioner "file" {
    content     = <<EOF
#!/bin/bash
echo "Running run=$GITHUB_RUN_ID (run_number=$GITHUB_RUN_NUMBER) job=$GITHUB_JOB ref=$GITHUB_REF sha=$GITHUB_SHA"
systemd-notify --ready
EOF
    destination = "/home/ubuntu/job-started.sh"
  }

  provisioner "file" {
    content     = <<EOF
[Unit]
Description=gha-runner
After=network-online.target
FailureAction=poweroff-immediate
SuccessAction=poweroff-immediate
JobTimeoutAction=poweroff-immediate
JobTimeoutSec=7h

[Service]
ExitType=cgroup
SyslogIdentifier=gha-runner
ExecStart=bash -c '/home/ubuntu/actions-runner/run.sh --jitconfig "$(cat /home/ubuntu/jit-token)"'
User=ubuntu
WorkingDirectory=/home/ubuntu/actions-runner
# Setup early kill if we don't get a job assigned. Note that bors will
# automatically spin up a replacement runner if it sees pending tasks.
# This hook is described here: https://github.com/actions/runner/blob/main/docs/adrs/1751-runner-job-hooks.md
Environment=ACTIONS_RUNNER_HOOK_JOB_STARTED=/home/ubuntu/job-started.sh
Type=notify
NotifyAccess=all
# If no job has been assigned in 3 minutes, we kill the instance.
TimeoutStartSec=3min
EOF
    destination = "/tmp/gha-runner.service"
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /etc/containers/",
      "sudo mv /tmp/containers.conf /etc/containers/containers.conf",
      "sudo mv /tmp/gha-runner.service /etc/systemd/system/gha-runner.service",
      "sudo chown root:root /etc/systemd/system/gha-runner.service",
      "sudo chmod a+r /etc/systemd/system/gha-runner.service",
      "sudo chmod a+x /home/ubuntu/job-started.sh",
      "sudo apt-get update",
      # https://github.com/actions/runner/blob/main/docs/start/envlinux.md
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y rustup gcc awscli liblttng-ust1t64 libkrb5-3 zlib1g libssl3 libicu78 docker.io docker-buildx jq python3-pip",
      "sudo usermod -a -G docker ubuntu",
      "sudo --login -u ubuntu bash -c 'rustup install stable --profile=minimal'",
      "sudo --login -u ubuntu bash -c 'mkdir actions-runner'",
      "sudo --login -u ubuntu bash -c 'cd actions-runner && curl -o runner.tar.gz -L ${var.runner_url}'",
      "sudo --login -u ubuntu bash -c 'cd actions-runner && tar xzf runner.tar.gz && rm runner.tar.gz'",
      # Make tmpfs mount on / rather than tmpfs, avoiding issues with running
      # out of space on small instances.
      "sudo systemctl mask tmp.mount",
      # Remove ssm agent since we don't use it.
      "sudo snap remove amazon-ssm-agent",
      # Recommended by @the8472 for performance given that we don't care about correctness.
      # Defaults as of writing are rw,relatime,discard,errors=remount-ro,commit=30
      # Check by `cat /proc/mounts | grep ext4`.
      "echo GRUB_CMDLINE_LINUX=\"rootflags=lazytime,barrier=0,data=writeback,noauto_da_alloc,journal_async_commit\" | sudo tee /etc/default/grub.d/99-packer-1.cfg",
      # Disable systemd getty - no point in providing console login since
      # there's no password that works. Instead we stream journal output to the
      # console for ssh-free viewing of current status (EC2 get-console-output
      # is a bit out of date so it's not perfect, but better than nothing).
      #
      # We also disable color to make it easier to view get-console-output
      # without escape codes interfering.
      "echo 'GRUB_CMDLINE_LINUX=\"systemd.getty_auto=no systemd.journald.forward_to_console=yes systemd.log_color=no\"' | sudo tee /etc/default/grub.d/99-packer-2.cfg",
      "sudo update-grub",
      # Prepare the snapshot for being used by new AMIs.
      "sudo cloud-init clean --configs all --seed --machine-id --logs",
    ]
  }
}
