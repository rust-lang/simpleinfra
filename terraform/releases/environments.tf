// Definition of the dev and production environments.
//
// The environments are completly separate, with no configuration shared
// between them. This reduces the chances of compromise between them.

module "dev" {
  source = "./impl"
  providers = {
    aws       = aws
    aws.east1 = aws.east1
  }

  bucket             = "dev-static-rust-lang-org"
  static_domain_name = "dev-static.rust-lang.org"
  doc_domain_name    = "dev-doc.rust-lang.org"

  inventories_bucket_arn = data.terraform_remote_state.shared.outputs.inventories_bucket_arn
}
