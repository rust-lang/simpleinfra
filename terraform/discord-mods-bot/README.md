# Discord moderation bot

This directory contains the Terraform configuration for the [Discord Moderation
Bot][bot-source] deployment and CI.

* [How to interact with our Terraform configuration](../README.md)
* [Documentation on the Forge][forge]

[forge]: https://forge.rust-lang.org/infra/docs/discord-mods-bot.html
[bot-source]: https://github.com/rust-lang/discord-mods-bot

## Configuration overview

### `deployment.tf`

Deployment of the bot in the production ECS cluster. This is the place to look
for if you need to tweak the environment the bot runs in.

### `ci.tf`

Definition of the ECR repository storing the containers built by CI, and the
user CI uses to authenticate to the repository.

### `_terraform.tf`

Terraform boilerplate.
