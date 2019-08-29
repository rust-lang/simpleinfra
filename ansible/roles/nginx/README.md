# `nginx` role

This role installs and configures the nginx web server on the instance. It
requires the [letsencrypt](../letsencrypt/README.md) role to be present as
well.

## Configuration

```yaml
- role: nginx

  # Configures reverse proxies with HTTPS termination. [optional]
  proxied:
      # The domain to proxy from
    - domain: subdomain.example.com
      # The destination to proxy to
      to: http://localhost:8000
```
