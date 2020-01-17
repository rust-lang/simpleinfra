// DNS records for the docsrs.com domain.
//
// Note that some of the records are managed by other Terraform resources, and
// thus are missing from this file!

module "docsrs_com" {
  source = "./impl"

  domain  = "docsrs.com"
  comment = "parked and reserved for future use"
  ttl     = 300
}
