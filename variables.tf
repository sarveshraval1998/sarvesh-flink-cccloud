variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "confluent_cluster" {
  description = "Confluent Cluster Name"
  type        = string
}

variable "confluent_environment" {
  description = "Confluent Environment Name"
  type        = string
}

variable "confluent_service_account" {
  description = "Confluent Service Account"
  type        = string
}

variable "confluent_sourcetopic" {
  description = "Confluent Source Topic"
  type        = string
  sensitive   = true
}

variable "confluent_sinktopic" {
  description = "Confluent Sink Topic"
  type        = string
  sensitive   = true
}

variable "confluent_connector" {
  description = "Confluent Connector Name"
  type        = string
  sensitive   = true
}

variable "confluent_srcluster_id" {
  description = "Confluent Schema Registry Cluster Id"
  type        = string
  sensitive   = true
}

variable "confluent_flink_endpoint" {
  description = "Confluent Flink Endpoint"
  type        = string
  sensitive   = true
}

variable "confluent_cluster_keyid" {
  description = "Confluent cluster key id"
  type        = string
  sensitive   = true
}

variable "confluent_cluster_keysecret" {
  description = "Confluent cluster key secret"
  type        = string
  sensitive   = true
}

variable "confluent_flink_keyid" {
  description = "Confluent flink key id"
  type        = string
  sensitive   = true
}

variable "confluent_flink_keysecret" {
  description = "Confluent flink key secret"
  type        = string
  sensitive   = true
}
