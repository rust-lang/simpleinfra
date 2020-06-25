output "arn" {
  value = aws_lambda_function.lambda.arn
}

output "version_arn" {
  value = aws_lambda_function.lambda.qualified_arn
}
