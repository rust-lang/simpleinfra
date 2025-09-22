use lambda_runtime::{service_fn, Error, LambdaEvent};
use serde::Deserialize;
use tracing_subscriber::{fmt, EnvFilter};

use url_list_lambda::{generate_tsv_from_bucket, JobInput};

#[tokio::main]
async fn main() -> Result<(), Error> {
    // Initialize tracing
    let filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));
    fmt().with_env_filter(filter).without_time().init();

    let func = service_fn(handler);
    lambda_runtime::run(func).await?;
    Ok(())
}

#[derive(Debug, Deserialize)]
struct Event(JobInput);

async fn handler(event: LambdaEvent<Event>) -> Result<String, Error> {
    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let s3 = aws_sdk_s3::Client::new(&config);
    let JobInput {
        bucket,
        prefix,
        base_url,
        output_bucket,
        output_key,
    } = event.payload.0;

    let tsv = generate_tsv_from_bucket(
        &s3,
        JobInput {
            bucket,
            prefix,
            base_url,
            output_bucket,
            output_key,
        },
    )
    .await?;
    Ok(tsv)
}
