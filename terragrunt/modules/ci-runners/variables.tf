// Since you can't create the connection from the terraform provider (as of Dec 2024),
// you need to create the connection manually at
// https://us-east-2.console.aws.amazon.com/codesuite/settings/connections
variable "rust_lang_code_connection_arn" {
  description = "Arn of the GitHub CodeConnection for https://github.com/rust-lang"
}

variable "rust_lang_ci_code_connection_arn" {
  description = "Arn of the GitHub CodeConnection for https://github.com/rust-lang-ci"
}
