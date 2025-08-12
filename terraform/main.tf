data "google_project" "current" {}

module "bigquery" {
  source     = "./modules/bigquery"
  dataset_id = "streaming_dest"
  tables = [{
    table_id            = "users"
    deletion_protection = false
    schema              = <<EOF
[
  {
    "name": "name",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The data"
  },
  {
    "name": "email",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The data"
  },
  {
    "name": "city",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The data"
  },
  {
    "name": "category",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The data"
  },
  {
    "name": "timestamp",
    "type": "TIMESTAMP",
    "mode": "NULLABLE",
    "description": "The data"
  }
]
EOF
  }]
}

# Service account
resource "google_service_account" "service_account" {
  account_id   = "pubsub-bq-sa"
  display_name = "Pub/Sub to BigQuery Service Account"
}

resource "google_project_iam_member" "bigquery_data_editor" {
  project = data.google_project.current.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "pubsub_subscriber" {
  project = data.google_project.current.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "pubsub_publisher" {
  project = data.google_project.current.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "service_account_token_creator" {
  project = data.google_project.current.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

module "pubsub" {
  source                     = "./modules/pubsub"
  topic_name                 = "streaming-source"
  schema_name                = "streaming-source-schema"
  schema_type                = "AVRO"
  schema_encoding            = "JSON"
  message_retention_duration = "86600s"
  schema_definition          = "{\n  \"type\" : \"record\",\n  \"name\" : \"Avro\",\n  \"fields\" : [\n    {\n      \"name\" : \"name\",\n      \"type\" : \"string\"\n    },\n    {\n      \"name\" : \"city\",\n      \"type\" : \"string\"\n    }\n  ]\n}\n"
  subscriptions = [
    {
      sa                  = google_service_account.service_account.email
      subscription_name   = "pubsubbq-topic-subscription"
      bq_use_topic_schema = true
      bq_table            = "${module.bigquery.tables[0].project}.${module.bigquery.tables[0].dataset_id}.${module.bigquery.tables[0].table_id}"
    }
  ]
}

# Artifact Registry
module "template_job_artifact" {
  source        = "./modules/artifact-registry"
  location      = var.location
  description   = "Pub/Sub to BigQuery Job"
  repository_id = "pubsub-bq-job"
  shell_command = "bash ${path.cwd}/scripts/artifact_push.sh ${data.google_project.current.project_id} ${var.location}"
}

module "template_bucket" {
  source        = "./modules/gcs"
  bucket_name   = "template-bucket-pubsub-bq-job"
  storage_class = "STANDARD"
  location      = var.location
  force_destroy = true
  objects = [
    {
      name   = "flex_template.json",
      source = "../src/flex_template.json"
    }
  ]
}

resource "google_dataflow_flex_template_job" "custom_job" {
  provider                = google-beta
  name                    = "pubsub-bq-dataflow-job"
  project                 = data.google_project.current.project_id
  container_spec_gcs_path = "gs://${module.template_bucket.name}/flex_template.json"
  parameters = {}
  enable_streaming_engine = true
  region                  = var.location
  on_delete               = "cancel"
  depends_on              = [module.template_bucket]
}
