resource "aws_ecr_repository" "repo" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "repo_lifecycle" {
  repository = aws_ecr_repository.repo.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Only keep the last 3 untagged images.",
      "selection": {
        "tagStatus": "untagged",
        "countType": "imageCountMoreThan",
        "countNumber": 3
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "push" {
  name = "ecr-push-${aws_ecr_repository.repo.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "push",
      "Effect": "Allow",
      "Action": [
        "ecr:CompleteLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "${aws_ecr_repository.repo.arn}"
    },
    {
      "Sid": "auth",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "pull" {
  name = "ecr-pull-${aws_ecr_repository.repo.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "push",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "${aws_ecr_repository.repo.arn}"
    },
    {
      "Sid": "auth",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}
EOF
}
