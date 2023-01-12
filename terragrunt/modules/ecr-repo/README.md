# `ecr-repo` Terraform module

The `ecr-repo` Terraform module creates a repository on ECR (AWS's container
registry) and two IAM Policies:

* `ecr-pull-{repo name}`: allows to pull from the repository
* `ecr-push-{repo name}`: allows to push to the repository

The repository has a lifecycle policy configured to store only tagged images and
the latest 3 untagged images: this will prevent its storage usage growing
indefinitely, while still allowing rollbacks to previous images.

You can find the input and output variables of this module in the
`variables.tf` and `outputs.tf` files respectively.
