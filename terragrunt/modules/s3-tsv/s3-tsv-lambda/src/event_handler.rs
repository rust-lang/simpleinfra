use lambda_runtime::{tracing::info, Error, LambdaEvent};
use serde_json::Value as JsonValue;

pub(crate) async fn function_handler(event: LambdaEvent<JsonValue>) -> Result<(), Error> {
    let payload = event.payload;

    // Try both shapes:
    // 1) Top-level: { "bucket": "..." }
    // 2) CloudWatch/EventBridge envelope: { "detail": { "bucket": "..." }, ... }
    let bucket = payload
        .get("bucket")
        .or_else(|| {
            payload.get("detail").and_then(|d| {
                info!("got bucket from detail");
                d.get("bucket")
            })
        })
        .and_then(|v| v.as_str())
        .ok_or("missing bucket in the payload")?;

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
    async fn test_event_handler_detail() {
        let e = serde_json::json!({
            "detail": { "bucket": "my-bucket-name" }
        });
        let event = LambdaEvent::new(e, Context::default());
        let response = function_handler(event).await.unwrap();
        assert_eq!((), response);
    }

    #[tokio::test]
    async fn test_event_handler_top_level() {
        let e = serde_json::json!({ "bucket": "top-level-bucket" });
        let event = LambdaEvent::new(e, Context::default());
        let response = function_handler(event).await.unwrap();
        assert_eq!((), response);
    }
}
