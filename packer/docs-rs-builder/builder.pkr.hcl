packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source = "github.com/hashicorp/amazon"
    }
  }
}

data "amazon-parameterstore" "revision" {
  name = "/docs-rs/builder/sha"
  region = "us-east-1"
}

locals {
  revision = data.amazon-parameterstore.revision.value
  pretty_revision = substr(local.revision, 0, 8)
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "docs-rs-builder-${local.pretty_revision}-${local.timestamp}"
  instance_type = "t2.large"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size   = 64
    delete_on_termination = true
  }
}

build {
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "ansible" {
    command = ".venv/bin/ansible-playbook"
    groups = ["docs-rs-builder"]
    inventory_directory = "./env"
    playbook_file = "./play/playbook.yml"
    # The default is the user running packer
    user = "ubuntu"
    extra_arguments = ["--extra-vars", "vars_repository_sha=${local.revision}"]
    # Work around for https://github.com/hashicorp/packer-plugin-ansible/issues/69
    ansible_ssh_extra_args = ["-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa"]
  }
}
