# devcontainers for `simpleinfra`

This repository provides an optional development container with tools for working
on `simpleinfra`. You can use it through a supported editor or the Dev Container CLI.
Using the development container is recommended, but optional.

## Overview

This project adopts [devcontainers] built on top of [Chainguard Wolfi]. This reduces
the exposure to critical vulnerabilities.

For example: a [trivy] scan in November 2026 reported four `HIGH`-severity findings in
bundled Go binaries and no `CRITICAL` findings. The scan reported no findings in Wolfi
packages:

```bash
trivy image \
    --image-src docker \
    --scanners \
    vuln simple-12105fa24503738d-features:latest \
    --severity HIGH,CRITICAL

2026-11-05T20:48:20+01:00	INFO	[vuln] Vulnerability scanning is enabled
2026-11-05T20:48:20+01:00	INFO	Detected OS	family="wolfi" version="20230201"
2026-11-05T20:48:20+01:00	INFO	[wolfi] Detecting vulnerabilities...	pkg_num=91
2026-11-05T20:48:20+01:00	INFO	Number of language-specific files	num=4
2026-11-05T20:48:20+01:00	INFO	[gobinary] Detecting vulnerabilities...

Report Summary

┌──────────────────────────────────────────────────────────┬──────────┬─────────────────┐
│                          Target                          │   Type   │ Vulnerabilities │
├──────────────────────────────────────────────────────────┼──────────┼─────────────────┤
│ simple-12105fa24503738d-features:latest (wolfi 20230201) │  wolfi   │        0        │
├──────────────────────────────────────────────────────────┼──────────┼─────────────────┤
│ usr/local/bin/aws-sso                                    │ gobinary │        1        │
├──────────────────────────────────────────────────────────┼──────────┼─────────────────┤
│ usr/local/bin/fastly                                     │ gobinary │        2        │
├──────────────────────────────────────────────────────────┼──────────┼─────────────────┤
│ usr/local/bin/terraform                                  │ gobinary │        0        │
├──────────────────────────────────────────────────────────┼──────────┼─────────────────┤
│ usr/local/bin/terragrunt                                 │ gobinary │        1        │
└──────────────────────────────────────────────────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

# more output
```

In addition, `simpleinfra.dockerfile` pins the versions of critical tools needed by users
of this repo.

## What is included

- `fish`
- `terraform`
- `terragrunt`
- `awscli2`
- `gcloud`
- `fastly`
- `python` and `uv`
- `rustup`, `cargo`, `rustc`
- `aws-sso`
- `openssh`

Check `simpleinfra.dockerfile` for the full list of available packages.

[devcontainers]: https://containers.dev
[Chainguard Wolfi]: https://github.com/wolfi-dev
[trivy]: https://github.com/aquasecurity/trivy

## Limitations

- running Ansible playbooks is still not supported.
- some standalone scripts like `with-rust-key.sh` are not supported.
- minimal Rust tooling installed, as required for Fastly compute functions

## How to use

### Code Editors

Both [zed] and [vscode] are supported, check instructions according to your
editor of choice. After opening this project within a container, the built-in
terminal should open `fish` and project files should be mounted.

[zed]: https://zed.dev/docs/dev-containers
[vscode]: https://code.visualstudio.com/docs/devcontainers/containers

### `devcontainers` CLI

- Install the [official devcontainers CLI]
- Launch a standalone `container`:

```bash
cd /path/to/simpleinfra
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . fish --login
```

[official devcontainers CLI]: https://containers.dev/supporting#devcontainer-cli

### MicroVMs

The container file can also be built and executed within a microVM. e.g. with
[Apple Containers]

The [brew formula for `container`] is actively maintained:

```bash
brew install container
```

- Build a microVM image

```bash
# starts the container daemon
container system start

cd /path/to/simpleinfra/.devcontainer
container build -f simpleinfra.dockerfile -t simpleinfra.local .
```

- Launch a microVM

```bash
# optional, container daemon must be started
# container system status
cd /path/to/simpleinfra/
container run -it -v "$PWD":/home/dev/workspace simpleinfra.local
```

[Apple Containers]: https://github.com/apple/container
[brew formula for `container`]: https://github.com/Homebrew/homebrew-core/blob/main/Formula/c/container.rb

## Cloud CLI authentication

Inside a container, the best way to authenticate `aws` or `gcloud` is through
a device-code authentication flow:

```bash
aws sso login --profile <PROFILE> --use-device-code --no-browser

# Authenticate Terraform through Application Default Credentials
gcloud auth application-default login --no-launch-browser
```

Check `terragrunt/README.md` for additional instructions.

## Personal customization

We define a `.devcontainer/custom` folder as a conventional point for extensions
decoupled from the container file definition. One can bring personal configuration
files, scripts, etc to it. All files within this folder are ignored in `git`. These
files are available after the workspace is mounted.
