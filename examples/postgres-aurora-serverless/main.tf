terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = ">= 2.48"
  region  = var.region
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

locals {

  name = "test"
}

module "rds" {
  source         = "../.."
  engine         = "aurora-postgresql"
  engine_version = "10.7"
  engine_mode    = "serverless"

  name_prefix                      = local.name
  subnet_ids                       = data.aws_subnet_ids.main.ids
  security_groups                  = [aws_security_group.app_servers.id]
  vpc_id                           = data.aws_vpc.main.id
  enable_http_endpoint             = true
  username                         = "superuser"
  password                         = "password"
  backup_retention_period          = "7"
  final_snapshot_identifier_prefix = "final-db-snapshot-prod"
  storage_encrypted                = true
  apply_immediately                = true
  monitoring_interval              = 10
  enable_cloudwatch_alarms         = true
  cloudwatch_sns_topic             = aws_sns_topic.db_alarms_postgres10.id
  db_parameter_group_name          = aws_db_parameter_group.rds.id
  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.rds.id

  scaling_configuration = {
    auto_pause               = true
    max_capacity             = 384
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  tags = {
    environment = "dev"
    terraform   = "True"
  }
}

resource "aws_sns_topic" "db_alarms_postgres10" {
  name = "${local.name}-db-alarms-postgres10"
}

resource "aws_db_parameter_group" "rds" {
  name        = "${local.name}-aurora-db-postgresql10-parameter-group"
  family      = "aurora-postgresql10"
  description = "${local.name}-parameter-group"
}

resource "aws_rds_cluster_parameter_group" "rds" {
  name        = "${local.name}-aurora-postgresql10-cluster-parameter-group"
  family      = "aurora-postgresql10"
  description = "${local.name}-cluster-parameter-group"
}


resource "aws_security_group" "app_servers" {
  name        = "app-servers"
  description = "For application servers"
  vpc_id      = data.aws_vpc.main.id
  tags = {
    Name = "app-servers"
  }
}
