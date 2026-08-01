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

source "amazon-ebs" "ubuntu" {
  ami_name = "${var.ami_name}"

  instance_type = "c8a.medium"
  region        = "us-east-2"

  temporary_security_group_source_public_ip = true
  ssh_clear_authorized_keys                 = true

  source_ami_filter {
    filters = {
      name                = "ubuntu-minimal/*ubuntu-resolute-26.04-amd64-minimal-*"
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
[Unit]
Description=gha-runner
After=network-online.target
# After we exit, successfully or not, kill the instance.
OnSuccess=poweroff.target
OnFailure=poweroff.target

[Service]
ExitType=cgroup
ExecStart=bash -c '/home/ubuntu/actions-runner/run.sh --jitconfig "$(cat /home/ubuntu/jit-token)"'
User=ubuntu
WorkingDirectory=/home/ubuntu/actions-runner
EOF
    destination = "/tmp/gha-runner.service"
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /etc/containers/",
      "sudo mv /tmp/containers.conf /etc/containers/containers.conf",
      "sudo mv /tmp/gha-runner.service /etc/systemd/system/gha-runner.service",
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
      # Recommended by @the8472 for performance given that we don't care about correctness.
      # Defaults as of writing are rw,relatime,discard,errors=remount-ro,commit=30
      # Check by `cat /proc/mounts | grep ext4`.
      "echo GRUB_CMDLINE_LINUX=\"rootflags=lazytime,barrier=0,data=writeback,noauto_da_alloc,journal_async_commit\" | sudo tee /etc/default/grub.d/99-packer.cfg",
      "sudo update-grub",
      # Prepare the snapshot for being used by new AMIs.
      "sudo cloud-init clean --configs all --seed --machine-id --logs",
    ]
  }
}
