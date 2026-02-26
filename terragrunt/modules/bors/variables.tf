variable "domain" {
  description = "domain to use"
}

variable "gh_app_id" {
  description = "GitHub App ID"
}

variable "trusted_sub" {
  description = "GitHub OIDC claim"
}

variable "oauth_client_id" {
  description = "OAuth client ID"
}

variable "public_url" {
  description = "Public URL for the bors instance. Used in GitHub comments."
}

variable "cpu" {
  description = "How much CPU should be allocated to the bors instance."
}

variable "memory" {
  description = "How much memory should be allocated to the bors instance."
}
