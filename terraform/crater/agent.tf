// This file contains the configuration for Crater agents.

resource "aws_iam_user" "agent_outside_aws" {
  name = "crater-agent--outside-aws"
}

resource "aws_iam_access_key" "agent_outside_aws" {
  user = aws_iam_user.agent_outside_aws.name
}

resource "aws_iam_role" "agent" {
  name = "crater-agent"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AssumeRoleEC2",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Effect": "Allow"
    },
    {
      "Sid": "AssumeRoleCraterAgentOutsideAWS",
      "Principal": {
        "AWS": "${aws_iam_user.agent_outside_aws.arn}"
      },
      "Action": "sts:AssumeRole",
      "Effect": "Allow"
    },
    {
        "Effect": "Allow",
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Principal": {
            "Federated": "accounts.google.com"
        },
        "Condition": {
            "StringEquals": {
                "accounts.google.com:sub": "${google_service_account.service_account.unique_id}"
            }
        }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "agent_pull_ecr" {
  role       = aws_iam_role.agent.name
  policy_arn = module.ecr.policy_pull_arn
}

data "aws_ssm_parameter" "token" {
  name            = "/prod/ansible/crater-gcp-2/crater-token"
  with_decryption = false
}

resource "aws_iam_policy" "read_crater_token" {
  name = "read-crater-token"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowReadingConnectionUrl"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = "${data.aws_ssm_parameter.token.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "read_crater_token" {
  role       = aws_iam_role.agent.name
  policy_arn = aws_iam_policy.read_crater_token.arn
}

resource "google_compute_health_check" "tcp_health" {
  name = "crater-agent-health-check"

  timeout_sec        = 5
  check_interval_sec = 15

  healthy_threshold   = 1
  unhealthy_threshold = 4

  log_config {
    enable = false
  }

  tcp_health_check {
    port = "4343"
  }
}

data "google_compute_image" "ubuntu_minimal" {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-minimal-2204-lts"
}

resource "google_compute_network" "crater" {
  name = "crater"
}

resource "google_compute_firewall" "default" {
  name    = "crater-firewall"
  network = google_compute_network.crater.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [22, 4343]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_service_account" "service_account" {
  account_id   = "crater-agent"
  display_name = "Crater Agent Account"
}

resource "google_compute_instance_template" "agent" {
  name_prefix      = "crater-agent-"
  machine_type     = "n2d-standard-16"
  min_cpu_platform = "AMD Milan"

  disk {
    auto_delete  = true
    boot         = true
    source_image = data.google_compute_image.ubuntu_minimal.self_link
    disk_size_gb = 100
    disk_type    = "pd-balanced"
  }

  scheduling {
    preemptible        = true
    provisioning_model = "SPOT"
    // Necessary for spot provisioning; we restart via the managed instance group
    automatic_restart = false
  }

  network_interface {
    network = google_compute_network.crater.name
    access_config {
      network_tier = "STANDARD"
    }
  }

  metadata = {
    startup-script = templatefile("startup-script.sh", {
      role       = aws_iam_role.agent.arn,
      docker_url = module.ecr.url
    })
    update-script = templatefile("update.sh", {
      role       = aws_iam_role.agent.arn,
      docker_url = module.ecr.url
    })
  }

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_autoscaler" "agents" {
  name   = "crater-autoscaler"
  target = google_compute_region_instance_group_manager.agents.id

  autoscaling_policy {
    max_replicas    = 6
    min_replicas    = 1
    cooldown_period = 120
    // This is pretty low, but in practice we want to scale out to the max
    // unless we're entirely idle: crater is either all up or all down.
    cpu_utilization {
      target = 0.1
    }
  }
}


resource "google_compute_region_instance_group_manager" "agents" {
  name = "crater-agents"

  base_instance_name = "crater-agent"

  version {
    instance_template = google_compute_instance_template.agent.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.tcp_health.id
    initial_delay_sec = 600
  }

  update_policy {
    type                           = "PROACTIVE"
    max_surge_fixed                = 0
    max_unavailable_fixed          = 3
    most_disruptive_allowed_action = "REPLACE"
    minimal_action                 = "REPLACE"
    replacement_method             = "RECREATE"
  }

  lifecycle {
    create_before_destroy = true
  }
}
