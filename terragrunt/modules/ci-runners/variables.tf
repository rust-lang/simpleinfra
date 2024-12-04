// Since you can't create the connection from the terraform provider (as of Dec 2024),
// you need to create the connection manually at
// https://us-east-2.console.aws.amazon.com/codesuite/settings/connections
variable "code_connection_arn" {
  description = "Arn of the GitHub CodeConnection"
}
