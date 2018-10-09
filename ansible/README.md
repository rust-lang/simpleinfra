# Servers configuration managed by Ansible

This directory contains the Ansible playbooks used by the Rust Infrastructure
team to configure our servers. These playbooks are released under the MIT
license.

## Available playbooks

This repository contains the following playbooks:

* `crater-agent`: deploy Crater agent machines
* `bastion`: deploy the bastion

## Execute the playbooks on the production servers

To execute a playbook on production you need to have ssh access on all the
involved machines. The playbooks require Ansible 2.7 and Python 3 installed on
the local machine to be run. Then you can use the `deploy` script:

```
$ ./deploy prod <playbook>
```

## Execute the playbooks on a local environment

Changes should be tested locally before being deployed on the production
servers. You can create a local development environment by copying the
`envs/prod` directory into `envs/dev.local` and customizing the files in there
to point to your local containers/VMs. Then you can use the `deploy` script:

```
$ ./deploy dev <playbook>
```

You can create as many environments as you like, and you don't need to type the
`.local` suffix in the deploy script (but it ignores the environment from git).

Since a few machines run Docker and requires changes to the boot configuration,
it's recommended to use virtual machines instead of containers in the local
environment. Tools like [multipass](https://github.com/CanonicalLtd/multipass)
can help you manage them.
