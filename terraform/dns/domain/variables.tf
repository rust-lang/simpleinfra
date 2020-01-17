// Basic information about the domain.

variable "domain" {
  description = "Domain name of the domain managed by this module"
  type        = string
}

variable "comment" {
  description = "Comment about the domain, shown in the console"
  type        = string
}

variable "ttl" {
  description = "Cache TTL for the records created by the module"
  type        = number
}

// List of records to create for this domain. Each record type has to be
// defined in the variable related to its kind.

variable "A" {
  description = "Map of A records and the list of their targets"
  type        = map(list(string))
  default     = {}
}

variable "CNAME" {
  description = "Map of CNAME records and the list of their targets"
  type        = map(list(string))
  default     = {}
}

variable "MX" {
  description = "Map of MX records and the list of their targets"
  type        = map(list(string))
  default     = {}
}

variable "TXT" {
  description = "Map of TXT records and the list of their content"
  type        = map(list(string))
  default     = {}
}
