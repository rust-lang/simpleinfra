// A Dedicated Host is an entire physical EC2 server allocated to this AWS
// account. Selecting the family rather than one instance type lets us divide
// its capacity among supported M9g sizes instead of fixing the host layout at
// allocation time. aws_ec2_host allocates an On-Demand host; it deliberately
// does not purchase a one- or three-year Dedicated Host Reservation because
// that is a separate, irreversible billing commitment with payment-term input.
resource "aws_ec2_host" "collector" {
  availability_zone = local.availability_zone
  instance_family   = local.instance_family

  // Require every instance to name this host explicitly. This prevents an
  // unrelated M9g launch in the account from silently consuming benchmark
  // capacity through EC2 auto-placement.
  auto_placement = "off"
}
