# Compute@Edge Function for `static.crates.io`

We are using a [Compute@Edge](https://docs.fastly.com/en/guides/compute-at-edge)
function on [Fastly](https://fastly.com) to route incoming traffic for
`static.crates.io` to S3. The function tries to get crates from the primary
bucket, and will fail-over to a fallback if it receives any HTTP `5xx`
responses.

## Deployment

After making changes to the function, make sure to build a new release package
and update the hash in [`fastly-static.tf`](../impl/fastly-static.tf). We
manually update the hash to prevent accidentally overwriting the function.

Build the function:

```shell
cd compute-static
fastly compute build
```

Calculate the hash:

```shell
cd compute-static
fastly compute hashsum
```

Copy the hash and paste it into [`fastly-static.tf`](../impl/fastly-static.tf).
Then run Terraform as usual.

```shell
export FASTLY_API_KEY=""
terraform plan
```
