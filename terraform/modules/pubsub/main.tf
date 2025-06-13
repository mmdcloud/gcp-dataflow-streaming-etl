resource "google_pubsub_schema" "schema" {
  name       = var.schema_name
  type       = var.schema_type
  definition = var.schema_definition
}

resource "google_pubsub_topic" "topic" {
  name = var.topic_name

  schema_settings {
    encoding = var.schema_encoding
    schema   = google_pubsub_schema.schema.id
  }
  message_retention_duration = var.message_retention_duration
}

resource "google_pubsub_subscription" "subscription" {
  count = length(var.subscriptions)
  name  = var.subscriptions[count.index].subscription_name
  topic = google_pubsub_topic.topic.id

  bigquery_config {
    service_account_email = var.subscriptions[count.index].sa
    use_topic_schema = var.subscriptions[count.index].bq_use_topic_schema
    table            = var.subscriptions[count.index].bq_table
  }
}
