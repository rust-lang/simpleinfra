locals {
  name = replace(var.static_domain_name, ".", "-")
}
