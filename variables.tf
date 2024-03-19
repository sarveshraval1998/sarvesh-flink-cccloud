variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "confluent_schema_registry_api_key" {
  description = "Confluent Schema Registry API Key"
  type        = string
}

variable "confluent_schema_registry_api_secret" {
  description = "Confluent Schema Registry API Secret"
  type        = string
  sensitive   = true
}
