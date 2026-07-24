resource "aws_launch_template" "runner" {
  name = "gha-runner"

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      delete_on_termination = true
      volume_type           = "gp3"
      volume_size           = 300
      throughput            = 800
      iops                  = 3500
    }
  }

  ebs_optimized = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  network_interfaces {
    // We use a public IP address rather than NAT gateways because it's both
    // easier and cheaper. Each NAT gateway is a minimum of $32/month,
    // whereas a public IPv4 IP is $3.6/month. And we typically want 3 NAT
    // gateways (one per AZ) to avoid cross-AZ bandwidth charges. We also don't
    // expect to always have live runner instances.
    //
    // In an ideal future GitHub will support IPv6 and we can have IPv6-only
    // runners. But in practice the cost of the IP is small compared to the
    // cost of the instances (~thousands of dollars a month).
    associate_public_ip_address = true

    delete_on_termination = true
    security_groups       = [aws_security_group.runner.id]
  }

  private_dns_name_options {
    hostname_type                        = "resource-name"
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
  }
}
