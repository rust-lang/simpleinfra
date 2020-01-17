// DNS records for the cratesio.com domain.
//
// Note that some of the records are managed by other Terraform resources, and
// thus are missing from this file!

module "cratesio_com" {
  source = "./impl"

  domain  = "cratesio.com"
  comment = "parked and reserved for future use"
  ttl     = 300
}
