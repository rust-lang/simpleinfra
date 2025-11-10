# Compute@Edge Function for `static.crates.io`

We are using a [Compute@Edge](https://docs.fastly.com/en/guides/compute-at-edge)
function on [Fastly](https://fastly.com) to route incoming traffic for
`static.crates.io` to S3. The function tries to get crates from the primary
bucket, and will fail over to a fallback if it receives any HTTP `5xx`
responses.

## Development

Install the Fastly CLI from [here](https://www.fastly.com/documentation/reference/tools/cli/#installing).

Then, build the function:

```shell
cd compute-static
fastly compute build
```

## Testing

Testing requires [cargo-nextest](https://nexte.st/docs/installation/pre-built-binaries/), as specified in
the [Fastly documentation](https://www.fastly.com/documentation/guides/compute/developer-guides/rust/). You can install
it from source with binstall:

```shell
cargo install cargo-binstall
cargo binstall cargo-nextest --secure
```

Then, install [Viceroy](https://github.com/fastly/Viceroy) to run the edge function locally:

```shell
cargo install --locked viceroy
```

Due to the fact Viceroy does not allow easily mocking HTTP requests being sent (
see [issue](https://github.com/fastly/Viceroy/issues/442)), some tests use a small Python HTTP
server to work.
For this reason, a wrapper bash script is provided that runs `cargo nextest run` with the test server active in
background. You can therefore run the tests with:
:

```shell
./run_tests.sh
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
