use aws_config::BehaviorVersion;
use aws_sdk_s3::Client;
use lambda_runtime::{tracing::info, Error, LambdaEvent};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct EventPayload {
    pub bucket: String,
}

pub(crate) async fn function_handler(event: LambdaEvent<EventPayload>) -> Result<(), Error> {
    let payload = event.payload;
    let bucket = payload.bucket.as_str();

    info!(payload=?payload, bucket, "Received event");

    // Initialize AWS S3 client
    let config = aws_config::load_defaults(BehaviorVersion::latest()).await;
    let client = Client::new(&config);

    // List objects in the bucket (limited to first 3)
    let response = client
        .list_objects_v2()
        .bucket(bucket)
        .max_keys(3)
        .send()
        .await?;
    info!("First 3 objects in bucket '{bucket}':");

    if let Some(objects) = response.contents {
        for (index, object) in objects.iter().enumerate() {
            let key = object.key().unwrap_or("<no key>");
            let size = object.size().unwrap_or(0);
            let last_modified = object
                .last_modified()
                .map(|dt| dt.to_string())
                .unwrap_or_else(|| "<no date>".to_string());

            println!(
                "{}. Key: {}, Size: {} bytes, Last Modified: {}",
                index + 1,
                key,
                size,
                last_modified
            );
        }

        if objects.is_empty() {
            return Err(Error::from(format!(
                "No objects found in bucket '{bucket}'"
            )));
        }
    } else {
        return Err(Error::from(format!(
            "No objects found in bucket '{bucket}'"
        )));
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use lambda_runtime::{Context, LambdaEvent};

    #[tokio::test]
    #[ignore = "requires AWS to run"]
    async fn test_event_handler() {
        let e = EventPayload {
            bucket: "top-level-bucket".to_string(),
        };
        let event = LambdaEvent::new(e, Context::default());
        let response = function_handler(event).await.unwrap();
        assert_eq!((), response);
    }
}
