# Compute@Edge Function for `static.crates.io`

We are using a [Compute@Edge](https://docs.fastly.com/en/guides/compute-at-edge)
function on [Fastly](https://fastly.com) to route incoming traffic for
`static.crates.io` to S3. The function tries to get crates from the primary
bucket, and will fail over to a fallback if it receives any HTTP `5xx`
responses.

## Development

Build the function:

```shell
cd compute-static
fastly compute build
```

## Deployment

Terraform uses an [external data source] to build the function as part of its
plan. This ensures that the function is always up-to-date, and prevents users
from accidentally uploading a stale version of the WASM module.

Export an API token for Fastly and then run Terraform:

```shell
export FASTLY_API_KEY=""
terraform plan
```

[external data source]: https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source
