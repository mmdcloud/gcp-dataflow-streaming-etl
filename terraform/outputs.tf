output "table_name" {
  value = module.bigquery.tables[0].name
}