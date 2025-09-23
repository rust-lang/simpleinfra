# Invoke the Lambda with a test payload
resource "aws_cloudwatch_event_rule" "test_event" {
  name                = "${local.name}-test-event"
  description         = "Trigger for ${local.name} to process a fixed bucket name"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "test_event_lambda" {
  rule      = aws_cloudwatch_event_rule.test_event.name
  target_id = "${local.name}-target"
  arn       = module.lambda.function_arn

  input = jsonencode({
    bucket = "hello"
  })
}

# Allow EventBridge to invoke the Lambda
resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromEventBridgeDaily"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.test_event.arn
}
