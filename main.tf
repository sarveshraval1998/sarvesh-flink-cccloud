terraform {
  cloud {
    organization = "flink_cccloud"

    workspaces {
      name = "cicd_flink_ccloud"
    }
  }

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.56.0"
    }
  }
}
locals {
  cloud  = "AWS"
  region = "us-east-2"
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

data "confluent_environment" "existing_env" {
  display_name = "Dev"  
}

data "confluent_schema_registry_region" "my_sr_region" {
  cloud   = local.cloud
  region  = local.region
  package = "ESSENTIALS"
}

resource "confluent_schema_registry_cluster" "my_sr_cluster" {
  package = data.confluent_schema_registry_region.my_sr_region.package

  environment {
    id = data.confluent_environment.existing_env.id  # Use the ID of the existing environment
  }

  region {
    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
    id = data.confluent_schema_registry_region.my_sr_region.id
  }

}

data "confluent_kafka_cluster" "existing_cluster" {
  display_name = "DF_AWS_DEV" 

  environment {
    id = data.confluent_environment.existing_env.id
  }
}

# Create a new Service Account. This will used during Kafka API key creation and Flink SQL statement submission.
data "confluent_service_account" "existing_service_account" {
  display_name = "sa-153094-dev"
  # You may need to provide additional filters to uniquely identify the existing service account
}

data "confluent_organization" "my_org" {}

# Assign the OrganizationAdmin role binding to the above Service Account.
# This will give the Service Account the necessary permissions to create topics, Flink statements, etc.
# In production, you may want to assign a less privileged role.
resource "confluent_role_binding" "my_org_admin_role_binding" {
  principal   = "User:${data.confluent_service_account.existing_service_account.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = data.confluent_organization.my_org.resource_name

  depends_on = [
    data.confluent_service_account.existing_service_account
  ]
}

# Create a new Kafka API key.
# This will be needed to create a Kakfa topic and to communicate with the Kafka cluster in general.
resource "confluent_api_key" "my_kafka_api_key" {
  display_name = "my_kafka_api_key"

  owner {
    id          = data.confluent_service_account.existing_service_account.id
    api_version = data.confluent_service_account.existing_service_account.api_version
    kind        = data.confluent_service_account.existing_service_account.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.existing_cluster.id
    api_version = data.confluent_kafka_cluster.existing_cluster.api_version
    kind        = data.confluent_kafka_cluster.existing_cluster.kind

    environment {
      id = data.confluent_environment.existing_env.id
    }
  }

  depends_on = [
    data.confluent_kafka_cluster.existing_cluster,
    confluent_role_binding.my_org_admin_role_binding
  ]
}

# Create a new Kafka topic. We will eventually ingest data from a Datagen connector into this topic.
resource "confluent_kafka_topic" "source_topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.existing_cluster.id
  }

  topic_name    = "source_topic"
  rest_endpoint = data.confluent_kafka_cluster.existing_cluster.rest_endpoint

  credentials {
    key    = confluent_api_key.my_kafka_api_key.id
    secret = confluent_api_key.my_kafka_api_key.secret
  }

  depends_on = [
    confluent_api_key.my_kafka_api_key
  ]
}

# Create a Datagen connector and ingest mock data into the source_topic created above.
resource "confluent_connector" "my_connector" {
  environment {
    id = data.confluent_environment.existing_env.id
  }

  kafka_cluster {
    id = data.confluent_kafka_cluster.existing_cluster.id
  }

  config_sensitive = {}

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "my_connector"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = data.confluent_service_account.existing_service_account.id
    "kafka.topic"              = confluent_kafka_topic.source_topic.topic_name
    "output.data.format"       = "AVRO"
    "quickstart"               = "ORDERS"
    "tasks.max"                = "1"
  }

  depends_on = [
    confluent_kafka_topic.source_topic
  ]
}
