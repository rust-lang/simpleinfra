variable "external-id" {
  type    = string
  default = "fc959d31-537c-4108-8b87-9af9e0c9b8d2"
}

variable "rolename" {
  type    = string
  default = "WizAccess-Role"
}

variable "remote-arn" {
  type    = string
  default = "arn:aws:iam::830522659852:role/prod-us43-AssumeRoleDelegator"
}
