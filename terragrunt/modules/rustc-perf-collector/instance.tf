resource "aws_instance" "collector" {
  count = local.instance_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = local.instance_type
  // host tenancy plus the explicit host ID places this instance on the
  // account's M9g physical server instead of the normal shared EC2 fleet.
  host_id                = aws_ec2_host.collector.id
  tenancy                = "host"
  subnet_id              = aws_subnet.collector.id
  vpc_security_group_ids = [aws_security_group.collector.id]
  // The public address is only for outbound package, toolchain, and benchmark
  // downloads. network.tf defines no ingress rules; administration goes
  // through SSM. This avoids a continuously billed NAT gateway.
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.collector.name

  // Accidental deletion would discard a calibrated benchmark environment. A
  // guest shutdown stops the partition rather than terminating its EBS volume;
  // it does not stop Dedicated Host billing while the physical host is
  // allocated. Detailed EC2 monitoring is unrelated to PMU counters.
  disable_api_termination              = true
  ebs_optimized                        = true
  instance_initiated_shutdown_behavior = "stop"
  monitoring                           = false

  // EC2 gives this script to cloud-init on the first boot. It installs the
  // native perf tooling, enables unprivileged PMU access, starts the SSM agent,
  // and runs a counter smoke test. It is bootstrap configuration, not a script
  // rerun by every Terraform apply.
  user_data = file("${path.module}/user-data.sh")

  // Require IMDSv2 and keep its packets local to the host, reducing the chance
  // that a benchmark process can accidentally expose instance-role credentials.
  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  // M9g is EBS-only. Provisioned gp3 performance reduces storage variance
  // during compilation, while 500 GiB leaves room for toolchains, sources, and
  // build artifacts. Encryption protects the persistent volume when stopped.
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 500 # GiB
  }

  tags = {
    Name        = "rustc-perf-graviton5-${count.index + 1}"
    Environment = "prod"
    Service     = "rustc-perf"
  }

  lifecycle {
    # Do not replace the collector just because Canonical published a new AMI.
    ignore_changes = [ami]
  }
}
