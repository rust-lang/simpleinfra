# Doman redirects

This directory contains the Terraform configuration for our redirects from a
whole subdomain to an URL.

* [How to interact with our Terraform configuration](../README.md)
* [Documentation on our domain redirects setup][forge]

[forge]: https://forge.rust-lang.org/infra/docs/dns.html

## Configuration overview

### `redirects.tf`

Definition of the redirects we have in our infrastructure. If you need to add
or tweak a redirect this is the place to look for.

### `impl/`

Custom module that actually defines the Terraform resources needed to maintain
a domain redirect. You should only need to tweak it if you need to change how
domain redirects work.

### `_terraform.tf`

Terraform boilerplate.
