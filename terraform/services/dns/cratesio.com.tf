module "cratesio_com" {
  source = "./domain"

  domain  = "cratesio.com"
  comment = "parked and reserved for future use"
  ttl     = 300
}
