# ACM Certificate

A module for creating a certificates that are verified using DNS validation.

## Dependencies

This module assumes that there are DNS zones for the parent domains of all domains passed to the module, unless you provide the hosted zone IDs directly.

For example, if the module is passed the domain `foo.bar.example.com`, the module assumes an existing DNS zone for `bar.example.com` where the cert validation DNS records will be placed.

If the zone is in a different AWS account or should not be looked up automatically, pass `zone_ids` keyed by zone name (e.g. `bar.example.com`) to bypass the lookup.
