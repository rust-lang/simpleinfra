locals {
  // The project requested the M9g (Graviton 5) family on a Dedicated Host.
  // Start with a 12xlarge partition: it provides 48 vCPUs and 192 GiB while
  // using one of the eight 12xlarge slots listed for an empty M9g host, leaving
  // capacity available for future M9g collectors.
  instance_family = "m9g"
  instance_type   = "m9g.12xlarge"

  // New instance families are not necessarily offered in every AZ. Select a
  // stable AZ ID from AWS's live offerings instead of hard-coding an AZ name
  // that can map differently between accounts.
  availability_zone_id = try(sort(data.aws_ec2_instance_type_offerings.collector.locations)[0], null)
}

// Use Canonical's official arm64 image: Graviton cannot boot the repository's
// usual amd64 AMIs. most_recent is safe here because instance.tf ignores later
// AMI changes to avoid silently replacing a benchmark machine.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ec2_instance_type_offerings" "collector" {
  filter {
    name   = "instance-type"
    values = [local.instance_type]
  }

  location_type = "availability-zone-id"
}

// The quota request records the desired value; this data source reads the
// actually approved value used by the host-allocation precondition.
data "aws_servicequotas_service_quota" "m9g_hosts" {
  service_code = "ec2"
  quota_code   = "L-9F9F275C"
}
