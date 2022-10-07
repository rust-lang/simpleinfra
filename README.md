# Simpleinfra

This repository containing the tools and automation written by the [Rust
infrastructure team][team] to manage our services. Using some of the tools in
this repo require privileges only infra team members have.

* [**ansible**](ansible/README.md): Ansible playbooks to deploy our servers
* [**aws-creds**][aws-2fa]: log into AWS with two factor authentication
* [**github-actions**](github-actions/README.md): shared actions for GitHub
  Actions
* [**setup-deploy-keys**](#setup-deploy-keys): automation for GitHub deploy keys
* [**terraform**](terraform/shared/README.md): Terraform configuration to deploy our
  cloud resources
* [**with-rust-key**](#with-rust-key): execute commands using the Rust release
  signing key

The contents of this repository are released under the MIT license.

[aws-2fa]: https://forge.rust-lang.org/infra/docs/aws-access.html#2-factor-authentication
[team]: https://github.com/rust-lang/infra-team

## setup-deploy-keys

Using Personal Access Tokens to upload to GitHub pages from CI is not great
from a security point of view, as it's not possible to scope those access
tokens to just that repository. Deploy keys are properly scoped, but it can be
an hassle to generate and configure them.

The `setup-deploy-keys` tool automates most of that process. You need to setup
your GitHub token in the `GITHUB_TOKEN` environment variable, and then run:

```
cargo run --bin setup-deploy-keys org-name/repo-name
```

The tool will generate a key, upload it to GitHub and then print an environment
variable `GITHUB_DEPLOY_KEY` containing an encoded representation of the
private key.

To use the key the easiest way is to cd into the directory you want to deploy,
[download this rust program][setup-deploy-keys-deploy], compile and run it
(with the `GITHUB_DEPLOY_KEY` variable set).

By default the tool generates ed25519 keys, but some libraries (like `git2`)
don't support them yet. In those cases you can generate RSA keys by passing the
`--rsa` flag:

```
cargo run --bin setup-deploy-keys org-name/repo-name --rsa
```

[setup-deploy-keys-deploy]: https://raw.githubusercontent.com/rust-lang/simpleinfra/master/setup-deploy-keys/src/deploy.rs

## with-rust-key

The `with-rust-key.sh` script executes a command inside a gpg environment
configured to use the Rust release signing key, without actually storing the
key on disk. The key is fetched at runtime from the 1password sensitive vault,
and you need to have `jq` and [the 1password CLI][1password-cli] installed.

For example, to create a git tag for the Rust 2.0.0 release you can use:

```
./with-rust-key.sh gpg tag -u FA1BE5FE 2.0.0 stable
```

The script is designed to leave no traces of the key on the host system after
it finishes, but a program with your user's privileges can still interact with
the key as long as the script is running.

[1password-cli]: https://support.1password.com/command-line-getting-started/
