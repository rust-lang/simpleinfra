# `nginx` role

This role installs and configures the nginx web server on the instance. It
requires the [letsencrypt](../letsencrypt/README.md) role to be listed before
this role as well.

## Configuration

```yaml
- role: nginx

  # The number of worker connections. [optional]
  # https://nginx.org/en/docs/ngx_core_module.html#worker_connections
  worker_connections: 123

  # Configures reverse proxies with HTTPS termination. [optional]
  proxied:
      # The domain to proxy from
    - domain: subdomain.example.com
      # The destination to proxy to
      to: http://localhost:8000
      # Additional `location` directives to proxy, beyond the default `/` location [optional]
      extra_locations:
          # The location to respond to
        - path: /my/awesome/location
          # The URL to proxy to
          to: http:127.0.0.1:9999/something
```
