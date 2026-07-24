resource "aws_default_vpc" "runner" {
}

resource "aws_security_group" "runner" {
  name        = "gha-runner"
  description = "Allows egress from GitHub actions runners"
  vpc_id      = aws_default_vpc.runner.id
}

resource "aws_vpc_security_group_egress_rule" "anywhere" {
  security_group_id = aws_security_group.runner.id
  // apt-get uses port 80 to reach ec2.archive.ubuntu.com
  for_each = toset(["443", "80"])

  // Our runners currently need fairly broad access. At minimum it'll be the **records** from here:
  // https://docs.github.com/en/actions/reference/runners/self-hosted-runners#requirements-for-communication-with-github
  // but in practice we also need S3, CloudFront, etc. Since we couldn't list out the GitHub records as IP addresses anyway, don't bother trying to restrict outbound access.
  //
  // For now we don't bother enforcing anything here except that there's no
  // outbound network access except TCP:443. If we run into needing more than
  // that we can likely relax this restriction.
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = each.key
  to_port     = each.key
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "simulacrum-ssh" {
  security_group_id = aws_security_group.runner.id
  cidr_ipv4         = "131.143.232.57/32"
  from_port         = "22"
  to_port           = "22"
  ip_protocol       = "tcp"
}
