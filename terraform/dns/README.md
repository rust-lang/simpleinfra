# DNS configuration

This directory contains the Terraform configuration for our domain names and
their DNS records.

Remember that only DNS records pointing to resources **not** managed by
Terraform are present here. Other Terraform resources will create the records
they need on their own.

* [How to interact with our Terraform configuration](../README.md)
* [Documentation on the project's DNS setup][forge]

[forge]: https://forge.rust-lang.org/infra/docs/dns.html

## Configuration overview

### `<DOMAIN_NAME>.tf`

Each domain name we own has a dedicated configuration file, containing the
definition of its DNS records. This is the place to look for if you just need
to tweak the records of a domain.

### `_shared.tf`

Variables that could be useful when creating DNS records, such as the list of
IP addresses to use when pointing an A record to GitHub Pages. Using variables
defined here should be preferred whenever possible.

### `impl/`

Custom module that actually defines the Terraform resources managing the DNS
records. All the `<DOMAIN_NAME>.tf` files import it. You should only need to
tweak it when you need to add an unsupported kind of DNS record.

### `_terraform.tf`

Terraform boilerplate.
