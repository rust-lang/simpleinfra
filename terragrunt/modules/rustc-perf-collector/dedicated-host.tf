// A Dedicated Host is an entire physical EC2 server allocated to this AWS
// account. Selecting the family rather than one instance type lets us divide
// its capacity among supported M9g sizes instead of fixing the host layout at
// allocation time. aws_ec2_host allocates an On-Demand host; it deliberately
// does not purchase a one- or three-year Dedicated Host Reservation because
// that is a separate, irreversible billing commitment with payment-term input.
resource "aws_ec2_host" "collector" {
  availability_zone = aws_subnet.collector.availability_zone
  instance_family   = local.instance_family

  // Require every instance to name this host explicitly. This prevents an
  // unrelated M9g launch in the account from silently consuming benchmark
  // capacity through EC2 auto-placement.
  auto_placement = "off"

  // M9g supports Dedicated Host recovery, so EC2 can allocate replacement
  // hardware after supported power or network failures. It does not cover
  // every failure mode (notably scheduled host retirement), which still needs
  // operator action.
  host_recovery = "on"

  tags = {
    Name        = "rustc-perf-graviton5"
    Environment = "prod"
    Service     = "rustc-perf"
  }

  lifecycle {
    precondition {
      condition     = local.availability_zone_id != null
      error_message = "${local.instance_type} is not offered in this AWS region."
    }

    // A quota request can exist in state while AWS is still reviewing it.
    // Gate host allocation on the applied quota because billing begins when
    // the Dedicated Host is allocated, even if it contains no instances.
    precondition {
      condition     = data.aws_servicequotas_service_quota.m9g_hosts.value >= var.required_dedicated_hosts
      error_message = "The Running Dedicated m9g Hosts quota increase must be approved before allocating the host."
    }
  }
}
