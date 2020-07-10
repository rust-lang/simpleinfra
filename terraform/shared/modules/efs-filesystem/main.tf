// Create the EFS filesystem.

resource "aws_efs_file_system" "efs" {
  creation_token = var.name

  tags = {
    Name = var.name
  }
}

// The EFS filesystem needs a mount point in each subnet to allow instances
// running in that subnet to communicate with it. This block queries
// information about that subnet, creates a security group restricting access
// to the mount point, and then creates the actual mount point in each provided
// subnet.

data "aws_subnet" "allowed_subnets" {
  for_each = toset(var.allow_subnets)
  id       = each.value
}

data "aws_vpc" "allowed_vpcs" {
  for_each = toset([for subnet in data.aws_subnet.allowed_subnets : subnet.vpc_id])
  id       = each.value
}

resource "aws_security_group" "efs_mount_targets" {
  for_each = data.aws_vpc.allowed_vpcs

  name        = "efs--${var.name}--mount-targets--${each.value.id}"
  description = "Allow traffic to the mount targets of the ${var.name} EFS filesystem."
  vpc_id      = each.value.id

  ingress {
    description = "NFS from the VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [each.value.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [each.value.cidr_block]
  }
}

resource "aws_efs_mount_target" "efs" {
  for_each = toset(var.allow_subnets)

  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = each.value
  security_groups = [
    aws_security_group.efs_mount_targets[data.aws_subnet.allowed_subnets[each.value].vpc_id].id
  ]
}

// Create a policy for the filesystem that only allows TLS access to EFS, and
// that requires IAM authentication to mount it (since there is no mount
// permission granted in the policy).

resource "aws_efs_file_system_policy" "efs" {
  file_system_id = aws_efs_file_system.efs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "RequireTLS"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action = "*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}

// Create a policy allowed to access the filesystem with root privileges.
//
resource "aws_iam_policy" "efs_root" {
  name = "efs--${var.name}--root"
  description = "Allow root access to the ${var.name} EFS filesystem."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowRootAccess"
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
        ]
        Resource = aws_efs_file_system.efs.arn
      }
    ]
  })
}
