packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "docs-rs-builder-${var.revision}"
  instance_type = "t2.large"
  region        = "us-east-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
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
    # The default is "default"
    host_alias = "docs-rs-builder"
    inventory_directory = "./env"
    playbook_file = "./play/playbook.yml"
    # The default is the user running packer
    user = "ubuntu"
  }
}
