# Azure Pipelines templates

This directory contains some shared Azure [Pipelines templates][docs] used on
CIs managed by the Rust Infrastructure team. There are no stability guarantees
for these templates, since they're supposed to only be used in infra managed by
us.

## Using the templates

In order to use any template from this repository you have to first let Azure
Pipelines know where to fetch them from by adding this snippet to the top of
the pipeline configuration:

```yaml
resources:
  repositories:
    - repository: rustinfra
      type: github
      name: rust-lang/simpleinfra
      endpoint: rust-lang
```

Then you can use all the templates in this repo by suffixing them with
`@rustinfra`:

```yaml
steps:
  - template: azure-configs/static-websites.yml@rustinfra
```

### static-websites.yml

The `static-websites.yml` template deploys a directory to GitHub pages using
deploy keys setup with the `setup-deploy-keys` tool in this repository.

```yaml
- template: azure-configs/static-websites.yml@rustinfra
  parameters:
    deploy_dir: path/to/output
    # Optional, only needed if GitHub pages is behind CloudFront
    cloudfront_distribution: AAAAAAAAAAAAAA
```

[docs]: https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops
