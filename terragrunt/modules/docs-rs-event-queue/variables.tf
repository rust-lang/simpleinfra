variable "consumer_principal_arns" {
  type        = list(string)
  description = "IAM principals allowed to consume events from the queue."
  default     = []
}
