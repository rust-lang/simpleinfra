# Packer

This directory contains configuration for running packer to build AMIs.

## The `packer` wrapper

This directory contains a python script named `packer` which wraps the system `packer`. The script creates an ansible virtual environment and moves the correct ansible configuration in place.

### Running `packer`

To run the wrapper pass the environment and playbook:

```bash
$ ./packer staging docs-rs-build
```
