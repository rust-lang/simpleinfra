# `common` role

This role applies the base server configuration all our instances require.
Currently it does these things:

* Install base APT packages
* Create users and assign permissions and SSH keys to them
* Configure the SSH server to disable insecure features
* Set the correct hostname
* Add a strict firewall with iptables
* Remove the default `ubuntu` user
* Configure backup manifests
* Setup [Prometheus]'s [node-exporter] to expose system metrics

[Prometheus]: https://prometheus.io
[node-exporter]: https://github.com/prometheus/node_exporter

## Backup manifests

Backup manifests are files located in `/etc/backup.d` that instruct the
[`backup`](../backup/README.md) role what it needs to backup. They have the
following schema:

```json
{
    "name": "backup-id",
    "path": "/path/to/backup",
    "before-script": "echo script to execute before the backup happens",
    "after-script": "echo script to execute after the backup happened"
}
```

The reason why backup manifests are used is they decouple the backup role from
the services it needs to backup, as they can define independently what they
want to preserve.

## Configuration

```yaml
- role: common

  # Users with access to the server and passwordless sudo privileges. [optional]
  # Their SSH keys will have to be present in roles/common/files/ssh-keys/${user}.pub
  sudo_users:
    - bors

  # Users with access to the server without sudo privileges. [optional]
  # Their SSH keys will have to be present in roles/common/files/ssh-keys/${user}.pub
  unprivileged_users:
    - rust-highfive

  # IP addresses allowed to query Prometheus metrics from node-exporter. [optional]
  # If the list is empty or missing node-exporter will be disabled.
  collect_metrics_from:
    - 127.0.0.1
```
