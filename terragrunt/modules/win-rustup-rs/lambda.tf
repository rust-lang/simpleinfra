module "origin_request" {
  source = "../aws-lambda"

  providers = {
    aws = aws.us-east-1
  }

  name       = "${local.human_readable_name}--origin-request"
  source_dir = "lambdas/origin-request"
  handler    = "index.handler"
  runtime    = "nodejs16.x"
  role_arn   = data.aws_iam_role.cloudfront_lambda.arn
}
