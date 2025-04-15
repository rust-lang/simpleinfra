resource "aws_codeconnections_connection" "github_connection" {
  name          = var.code_connection_name
  provider_type = "GitHub"
}
