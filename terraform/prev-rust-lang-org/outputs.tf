output "certificate_arn" {
  value       = module.certificate.arn
  description = "ARN of the ACM certificate for prev.rust-lang.org and beta.rust-lang.org."
}
