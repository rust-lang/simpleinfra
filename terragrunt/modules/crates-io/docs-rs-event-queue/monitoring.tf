locals {
  datadog_queue_filter = "queue_name:${local.queue_name},env:${var.env}"
  datadog_tags = [
    "component:crates-io-events",
    "env:${var.env}",
    "queue_name:${local.queue_name}",
    "service:docs-rs",
  ]
}

resource "datadog_monitor" "queue_backlog" {
  name    = "[${var.env}] docs.rs crates.io event queue backlog"
  type    = "query alert"
  message = "docs.rs is falling behind processing crates.io events from `${local.queue_name}`."
  query   = "avg(last_15m):max:aws.sqs.approximate_number_of_messages_visible{${local.datadog_queue_filter}} > ${var.backlog_critical_threshold}"

  monitor_thresholds {
    warning  = var.backlog_warning_threshold
    critical = var.backlog_critical_threshold
  }

  include_tags        = true
  notify_no_data      = false
  require_full_window = false
  tags                = local.datadog_tags
}

resource "datadog_monitor" "oldest_message_age" {
  name    = "[${var.env}] docs.rs crates.io event queue oldest message age"
  type    = "query alert"
  message = "The oldest visible message in `${local.queue_name}` is too old, which indicates docs.rs is not draining crates.io events quickly enough."
  query   = "avg(last_15m):max:aws.sqs.approximate_age_of_oldest_message{${local.datadog_queue_filter}} > ${var.oldest_message_age_critical_seconds}"

  monitor_thresholds {
    warning  = var.oldest_message_age_warning_seconds
    critical = var.oldest_message_age_critical_seconds
  }

  include_tags        = true
  notify_no_data      = false
  require_full_window = false
  tags                = local.datadog_tags
}

resource "datadog_dashboard_json" "queue" {
  dashboard = jsonencode({
    title       = "docs.rs crates.io event queue (${var.env})"
    description = "SQS FIFO queue used by crates.io to notify docs.rs about registry changes."
    layout_type = "ordered"
    widgets = [
      {
        definition = {
          type      = "query_value"
          title     = "Visible messages"
          autoscale = true
          precision = 0
          requests = [
            {
              q          = "max:aws.sqs.approximate_number_of_messages_visible{${local.datadog_queue_filter}}"
              aggregator = "last"
            }
          ]
        }
      },
      {
        definition = {
          type      = "query_value"
          title     = "Oldest message age"
          autoscale = true
          precision = 0
          requests = [
            {
              q          = "max:aws.sqs.approximate_age_of_oldest_message{${local.datadog_queue_filter}}"
              aggregator = "last"
            }
          ]
        }
      },
      {
        definition = {
          type  = "timeseries"
          title = "Queue depth"
          requests = [
            {
              q            = "max:aws.sqs.approximate_number_of_messages_visible{${local.datadog_queue_filter}}"
              display_type = "line"
            },
            {
              q            = "max:aws.sqs.approximate_number_of_messages_not_visible{${local.datadog_queue_filter}}"
              display_type = "line"
            }
          ]
        }
      },
      {
        definition = {
          type  = "timeseries"
          title = "Message throughput"
          requests = [
            {
              q            = "sum:aws.sqs.number_of_messages_sent{${local.datadog_queue_filter}}.as_count()"
              display_type = "bars"
            },
            {
              q            = "sum:aws.sqs.number_of_messages_received{${local.datadog_queue_filter}}.as_count()"
              display_type = "bars"
            },
            {
              q            = "sum:aws.sqs.number_of_messages_deleted{${local.datadog_queue_filter}}.as_count()"
              display_type = "bars"
            }
          ]
        }
      }
    ]
  })
}
