# Compute@Edge Function for `static.crates.io`

We are using a [Compute@Edge](https://docs.fastly.com/en/guides/compute-at-edge)
function on [Fastly](https://fastly.com) to route incoming traffic for
`static.crates.io` to S3. The function tries to get crates from the primary
bucket, and will fail over to a fallback if it receives any HTTP `5xx`
responses.

## Deployment

Build the function:

```shell
cd compute-static
fastly compute build
```

Export an API token for Fastly and then run Terraform:

```shell
export FASTLY_API_KEY=""
terraform plan
```
