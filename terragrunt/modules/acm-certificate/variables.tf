variable "domains" {
  description = "List of domain names included in the certificate"
  type        = list(string)
}

variable "legacy" {
  description = "Set to true for certificates in the legacy account"
  type        = bool
}

variable "zone_ids" {
  # Optional overrides to avoid Route 53 lookups.
  description = "Optional map of Route 53 hosted zone IDs keyed by zone name (e.g. rust-lang.org)."
  type        = map(string)
  default     = {}
}
