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
    // Also print to stdout for easy CloudWatch Logs grepping
    println!("bucket={}", bucket);

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use lambda_runtime::{Context, LambdaEvent};

    #[tokio::test]
    async fn test_event_handler() {
        let e = EventPayload {
            bucket: "top-level-bucket".to_string(),
        };
        let event = LambdaEvent::new(e, Context::default());
        let response = function_handler(event).await.unwrap();
        assert_eq!((), response);
    }
}
