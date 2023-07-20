# Packer

This directory contains configuration for running packer to build AMIs.

## Dependencies

Running these packer scripts requires the following software:

- python3
- [packer](https://developer.hashicorp.com/packer/downloads)
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## The `packer` wrapper

This directory contains a python script named `packer` which wraps the system `packer`. The script creates an ansible virtual environment and moves the correct ansible configuration in place.

### Running `packer`

Before running the packer script, you will need to initialize packer:

```bash
packer init ./docs-rs-builder
```

You will also need to make sure that you are logged into the correct AWS account in the AWS cli. First, ensure you have the configuration needed to log into the appropriate AWS account in your "~/.aws/config" file (TODO: link to detailed instructions).

For example, to log into the docs-rs staging account, run:

```bash
aws sso login --profile docs-rs-staging
```

To run the wrapper pass the environment and playbook along with the profile name of the aws account you just logged into:

```bash
$ AWS_PROFILE=docs-rs-staging ./packer staging docs-rs-builder
```
