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

data "confluent_kafka_cluster" "existing_cluster" {
  display_name = "DF_AWS_DEV" 

  environment {
    id = data.confluent_environment.existing_env.id
  }
}


# Create a new Service Account. This will used during Kafka API key creation and Flink SQL statement submission.
data "confluent_service_account" "existing_service_account" {
  display_name = "SA-153094-DF-SSConDep"
  # You may need to provide additional filters to uniquely identify the existing service account
}

data "confluent_organization" "my_org" {}

# Create a new Kafka topic. We will eventually ingest data from a Datagen connector into this topic.
resource "confluent_kafka_topic" "source_topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.existing_cluster.id
  }

  topic_name    = "source_topic"
  rest_endpoint = data.confluent_kafka_cluster.existing_cluster.rest_endpoint

  credentials {
    key    = "D7HW535CCPSZY36R"
    secret = "jZARSXEVto08v5pnflOQAdhOdmJfZc70+it40obKhas/PydZV5/oqj1GPui7WiQo"
  }
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

# Create a new Kafka topic. We will eventually ingest data from our source_topic via a Flink SQL statement into this topic.
resource "confluent_kafka_topic" "sink_topic" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.existing_cluster.id
  }

  topic_name    = "sink_topic"
  rest_endpoint = data.confluent_kafka_cluster.existing_cluster.rest_endpoint

  credentials {
    key    = "D7HW535CCPSZY36R"
    secret = "jZARSXEVto08v5pnflOQAdhOdmJfZc70+it40obKhas/PydZV5/oqj1GPui7WiQo"
  }
}

# Create a Schema Registry API key to interact with the Schema Registry cluster we created above.
resource "confluent_api_key" "my_sr_api_key" {
  display_name = "my_sr_api_key"

  owner {
    id          = data.confluent_service_account.existing_service_account.id
    api_version = data.confluent_service_account.existing_service_account.api_version
    kind        = data.confluent_service_account.existing_service_account.kind
  }

  managed_resource {
    id          = "lkc-6o2q52"
    api_version = "srcm/v2"
    kind        = "Cluster"

    environment {
      id = data.confluent_environment.existing_env.id
    }
  }
}

# Attach a schema to the sink_topic.
resource "confluent_schema" "my_schema" {
  schema_registry_cluster {
    id = data.confluent_kafka_cluster.existing_cluster.id
  }

  rest_endpoint = data.confluent_kafka_cluster.existing_cluster.rest_endpoint
  subject_name  = "${confluent_kafka_topic.sink_topic.topic_name}-value"
  format        = "AVRO"
  schema        = file("./schemas/avro/my_schema.avsc")

  credentials {
    key    = confluent_api_key.my_sr_api_key.id
    secret = confluent_api_key.my_sr_api_key.secret
  }

  depends_on = [
    confluent_api_key.my_sr_api_key,
    confluent_kafka_topic.sink_topic
  ]
}
