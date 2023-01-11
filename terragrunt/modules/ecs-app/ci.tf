// ECR repository which will store the Docker image powering the application.

module "ecr" {
  source = "../ecr-repo"
  name   = var.name
}

// TODO: reenanle
// IAM User used by GitHub Actions to pull and push images to ECR, and to
// restart the ECS service once the image is uploaded. The credentials will
// be added automatically to the GitHub Actions secrets.

# module "iam_ci" {
#   source = "../gha-iam-user"
#   org    = split("/", var.repo)[0]
#   repo   = split("/", var.repo)[1]
# }

# resource "aws_iam_user_policy" "update_service" {
#   name = "update-ecs-service"
#   user = module.iam_ci.user_name

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid      = "AllowUpdate"
#         Effect   = "Allow"
#         Action   = "ecs:UpdateService"
#         Resource = module.ecs_service.arn
#       }
#     ]
#   })
# }

# resource "aws_iam_user_policy_attachment" "ci_pull" {
#   user       = module.iam_ci.user_name
#   policy_arn = module.ecr.policy_pull_arn
# }

# resource "aws_iam_user_policy_attachment" "ci_push" {
#   user       = module.iam_ci.user_name
#   policy_arn = module.ecr.policy_push_arn
# }
