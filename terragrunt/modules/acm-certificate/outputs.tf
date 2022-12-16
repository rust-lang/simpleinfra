output "arn" {
  value       = aws_acm_certificate_validation.cert.certificate_arn
  description = "The ARN of the certificate"
}
