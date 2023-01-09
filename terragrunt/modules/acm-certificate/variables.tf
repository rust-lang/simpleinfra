variable "domains" {
  description = "List of domain names included in the certificate"
  type        = list(string)
}

variable "legacy" {
  description = "Set to true for certificates in the legacy account"
  type        = bool
}
