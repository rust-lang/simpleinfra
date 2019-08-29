# `letsencrypt` role

This role installs and configures the [lego] Let's Encrypt client and setups a
timer to try and renew the certificate each week. The certificate will be
stored in `/etc/ssl/letsencrypt/certificates`.

If the `dummy_certs` variable is set to `true` the role will install on the
instance [the dummy ACME server Pebble][pebble] and use it to request a
self-signed certificate. Pebble will skip any kind of validation, so it's great
when testing a playbook locally.

## Configuration

```yaml
- role: letsencrypt
  # Email used to register the Let's Encrypt account.
  email: admin@example.com
  # List of domains to include in the certificate.
  domains:
    - example.org
    - example.com
  # Whether to request the certificate from Let's Encrypt (`false`) or a local
  # dummy CA (`true`). The default is `false`
  dummy_certs: false
```

[lego]: https://go-acme.github.io/lego/
[pebble]: https://github.com/letsencrypt/pebble
