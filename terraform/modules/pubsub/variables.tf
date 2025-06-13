variable "schema_name" {}
variable "schema_type" {}
variable "schema_definition" {}

variable "topic_name" {}
variable "schema_encoding" {}
variable "message_retention_duration" {}

variable "subscriptions" {
  type = list(object({
    subscription_name = string
    bq_use_topic_schema = bool
    bq_table = string
    sa = string
  }))
}