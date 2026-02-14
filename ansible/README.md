# Ansible playbooks

This directory contains the [Ansible] playbooks used to configure the servers
managed by the Rust Infrastructure team.

## Executing a playbook

To execute a playbook you'll need to have Python 3 installed on the local
machine and, if the environment requires it, AWS credentials. Then you can
execute this command:

```
./apply <environment> <playbook>
```

For example:

```
./apply prod monitoring
```

The playbook is the name of a file inside the `playbooks/` directory without
the extension.

### Executing a playbook on a new server

By default the `./apply` script uses your current username to connect to the
server, but that might not be present the first time you want to execute a
playbook on a new server. You can override the user by passing the `-u` flag to
the `./apply` script followed by the username you want to use:

```
./apply <environment> <playbook> -u <username>
```

### Permissions

In order to run the `./apply` script, you need SSH permissions for the user
on the host. If the host does not already have a public key for the given
user, you can consider temporarily pushing one to the host using the AWS CLI.

```
aws ec2-instance-connect send-ssh-public-key \
    --instance-id $HOST_INSTANCE_ID \
    --instance-os-user $USER \
    --ssh-public-key file://$PATH_TO_PUBLIC_KEY \
    --region $REGION \
    --profile $AWS_PROFILE
```

You will then have 60 seconds to kick off the `./apply` script before the
public key is removed again.

> [!NOTE]
> If the server is an fresh Ubuntu instance, use `ubuntu` as `$USER`, and
> run ansible with the `-u ubuntu` flag.
> E.g.:
>
> ```sh
> $ aws ec2-instance-connect send-ssh-public-key [...] --instance-os-user 'ubuntu' [...]
> $ ./apply [...] -u ubuntu
> ```

## Environments

Making changes directly on production is not a great idea: to ease local
development the `./apply` script supports "environments". An environment is a
subdirectory inside `envs/` that contains an `hosts` file and optionally some
variables inside `group_vars`.

At the moment the only working environment present in the repository is `prod`,
which points to our production servers. To run a playbook on it you'll have to
be a member of the infrastructure team with proper access.

The `dev-example` environment instead is a dummy one with all the hostnames and
credentials replaced with dummy data. For local development is recommended to
copy it to `envs/dev` (which is properly gitignored) and replace everything
with your local development credentials. Everyone should be able to do it.

> Note: environments are **not** an Ansible feature, they're fully implemented
> in the `./apply` script.

## Overview of the configuration

### Playbooks

A playbook is a list of roles to apply to a group of servers with some
configuration attached to them. If you need to tweak a setting in a server's
configuration you'll probably just need to tweak the playbook.

Playbooks live in the `playbooks/` directory.

### Roles

A role is an isolated entity that contains all the necessary resources to
deploy and configure a service in a server. Roles can't be applied directly but
they need to be added to a playbook.

Roles live in the `roles/` directory, and each of them has its own `README`.

### Variables

Variables contain configuration values that change between environments or that
are shared between multiple playbooks. Global variables are loaded from
multiple files, and can be overridden by the next file loaded. The order is the
following:

* `envs/<env>/group_vars/all.yml`
* `group_vars/all.yml`
* `envs/<env>/group_vars/<group>.yml`
* `group_vars/<group>.yml`

## Resources

* [Ansible documentation][Ansible]

[Ansible]: https://docs.ansible.com/ansible/
[op]: https://app-updates.agilebits.com/product_history/CLI
