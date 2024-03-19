terraform {
  cloud {
    organization = "flink_ccccloud"

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

resource "confluent_kafka_cluster" "my_kafka_cluster" {
  display_name = data.confluent_kafka_cluster.existing_cluster.display_name
  availability = data.confluent_kafka_cluster.existing_cluster.availability
  cloud        = local.cloud
  region       = local.region
  basic {}

  environment {
    id = data.confluent_kafka_cluster.existing_cluster.environment.id
  }

}
