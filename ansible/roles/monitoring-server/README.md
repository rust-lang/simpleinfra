# `monitoring-server` role

This role configures a monitoring server with [Prometheus], [Alertmanager] and
[Grafana]. It requires the [`postgresql`](../postgresql/README.md) role to be
configured.

[Prometheus]: https://prometheus.io
[Alertmanager]: https://prometheus.io/docs/alerting/alertmanager/
[Grafana]: https://grafana.com

## Configuration

```yaml
- role: monitoring-server
  # How frequently Prometheus will scrape the sources. [optional, default `15s`]
  prometheus_scrape_interval: 15s
  # Data retention period for Prometheus. [optiona, default `15d`]
  prometheus_retention: 15d
  # Timeout to mark alerts as resolved if the metrics stop firing.
  # [optional, default `5m`]
  alertmanager_resolve_timeout: 5m
  # List of Prometheus scrape jobs. [optional]
  # https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config
  prometheus_scrape: []
  # List of Prometheus rule groups managed by Ansible. [optional]
  # https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/#rule_group
  prometheus_rule_groups: []
  # Alertmanager's routing configuration. [optional]
  # https://prometheus.io/docs/alerting/configuration/#route
  alertmanager_route: {}
  # Alertmanager's receivers. [optional]
  # https://prometheus.io/docs/alerting/configuration/#receiver
  alertmanager_receivers: []
  # Alertmanager's inhibition rules. [optional]
  alertmanager_inhibit_rules: []
  # List of GitHub team IDs allowed to log into Grafana. [optional]
  # It's possible to get the IDs from the API.
  grafana_github_teams: []
  # Name of the domain serving Grafana.
  grafana_domain: grafana.example.com
  # Password of Grafana's admin account.
  grafana_admin_password: passw0rd
  # Client ID of the GitHub OAuth application used for logging in.
  grafana_github_oauth_id: aaaaaaaaaaaaaaaaaaaa
  # Client secret of the GitHub OAuth application used for logging in.
  grafana_github_oauth_secret: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  # Name of the PostgreSQL database.
  grafana_db_name: grafana
  # Name of the PostgreSQL user.
  grafana_db_user: grafana
  # The PostgreSQL user's password.
  grafana_db_password: passw0rd
```
