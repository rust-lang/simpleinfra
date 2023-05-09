variable "services" {
  description = "List of Fastly services"
  type = map(object({
    env = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for e in var.services :
      contains(["staging", "prod"], e.env)
    ])
    error_message = "The environment must be 'staging' or 'prod'."
  }
}
