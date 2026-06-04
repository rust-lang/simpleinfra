# rust-lang.org

This directory contains the Terraform configuration for rust-lang.org subdomains
that are managed outside the main website deployment.

Currently this includes `prev.rust-lang.org` and `beta.rust-lang.org`.

The `prev.rust-lang.org` CloudFront Function redirects traffic to
`https://rust-lang.org`, preserving the incoming request path.
