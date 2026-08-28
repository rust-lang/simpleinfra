resource "aws_instance" "collector" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = local.instance_type
  subnet_id              = aws_default_subnet.collector.id
  vpc_security_group_ids = [aws_security_group.collector.id]
  ipv6_address_count     = 1

  // Don't assign a public IPv4, because we use Elastic IP to get a stable address.
  associate_public_ip_address = false

  // Enable EC2 Instance Termination Protection.
  disable_api_termination = true
  monitoring              = false

  metadata_options {
    http_endpoint = "enabled"
    // Disable the IMDS IPv6 endpoint
    http_protocol_ipv6 = "disabled"
    // Limit IMDSv2 token responses to one network hop.
    http_put_response_hop_limit = 1
    // Reject tokenless IMDSv1 requests by requiring an IMDSv2 session token.
    http_tokens            = "required"
    instance_metadata_tags = "disabled"
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = 500 # GiB
  }

  lifecycle {
    # Do not replace the collector just because Canonical published a new AMI.
    ignore_changes = [ami]
  }
}

// Static IP.
resource "aws_eip" "collector" {
  domain = "vpc"
}

resource "aws_eip_association" "collector" {
  allocation_id = aws_eip.collector.id
  instance_id   = aws_instance.collector.id
}
