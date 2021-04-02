
locals {
  port                 = var.port == "" ? var.engine == "aurora-postgresql" ? "5432" : "3306" : var.port
  master_password      = var.password == "" ? random_password.master_password.result : var.password
  db_subnet_group_name = var.db_subnet_group_name == "" ? join("", aws_db_subnet_group.main.*.name) : var.db_subnet_group_name
  backtrack_window     = (var.engine == "aurora-mysql" || var.engine == "aurora") && var.engine_mode != "serverless" ? var.backtrack_window : 0

  rds_enhanced_monitoring_arn  = join("", aws_iam_role.rds_enhanced_monitoring.*.arn)
  rds_enhanced_monitoring_name = join("", aws_iam_role.rds_enhanced_monitoring.*.name)

  security_group_id = join("", aws_security_group.main.*.id)

  name = var.name_prefix

  instances_required = var.replica_scale_enabled ? var.replica_scale_min : var.instance_count
}

# -------------------------------------------------------------------------------
# Resources
# -------------------------------------------------------------------------------
data "aws_availability_zones" "available" {
}

resource "aws_rds_cluster" "main" {
  depends_on = [aws_db_subnet_group.main]

  cluster_identifier        = "${local.name}-cluster"
  global_cluster_identifier = var.global_cluster_identifier
  availability_zones        = var.availability_zones

  replication_source_identifier = var.replication_source_identifier

  database_name   = var.database_name
  master_username = var.username
  master_password = local.master_password
  port            = var.engine_mode != "serverless" ? local.port : null


  engine         = var.engine
  engine_mode    = var.engine_mode
  engine_version = var.engine_version

  enable_http_endpoint = var.enable_http_endpoint

  db_subnet_group_name         = aws_db_subnet_group.main.name
  vpc_security_group_ids       = compact(concat(aws_security_group.main.*.id, var.vpc_security_group_ids))
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  snapshot_identifier          = var.snapshot_identifier
  final_snapshot_identifier    = "${join("-", compact([var.final_snapshot_identifier_prefix, local.name]))}-final-${random_string.suffix.result}"
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot
  skip_final_snapshot          = var.skip_final_snapshot

  deletion_protection = var.deletion_protection
  backtrack_window    = local.backtrack_window

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_arn

  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name

  iam_roles                           = var.iam_roles
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  dynamic "scaling_configuration" {
    for_each = length(keys(var.scaling_configuration)) == 0 ? [] : [
    var.scaling_configuration]

    content {
      auto_pause               = lookup(scaling_configuration.value, "auto_pause", null)
      max_capacity             = lookup(scaling_configuration.value, "max_capacity", null)
      min_capacity             = lookup(scaling_configuration.value, "min_capacity", null)
      seconds_until_auto_pause = lookup(scaling_configuration.value, "seconds_until_auto_pause", null)
      timeout_action           = lookup(scaling_configuration.value, "timeout_action", null)
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-cluster"
    },
  )

  lifecycle {
    create_before_destroy = true

    ignore_changes = [
      # Ignore changes to AZs, because Amazon will set these
      availability_zones,
      engine_version,
    ]
  }

  apply_immediately = var.apply_immediately
}

resource "aws_rds_cluster_instance" "main" {
  count = var.engine_mode != "serverless" ? local.instances_required : 0

  identifier         = "${local.name}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_type

  engine                  = var.engine
  engine_version          = var.engine_version
  db_subnet_group_name    = aws_db_subnet_group.main.name
  db_parameter_group_name = var.db_parameter_group_name

  publicly_accessible          = var.publicly_accessible
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_role_arn          = local.rds_enhanced_monitoring_arn
  monitoring_interval          = var.monitoring_interval
  preferred_maintenance_window = var.preferred_maintenance_window

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name_prefix}-instance-${count.index + 1}"
    },
  )

  apply_immediately = var.apply_immediately

  lifecycle {
    ignore_changes = [
      engine_version,
    ]
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.name_prefix}-subnet-group"
  description = "Terraformed RDS ${local.name}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    var.tags,
    {
      "Name" = "${local.name}-subnet-group"
    },
  )
}

resource "aws_security_group" "main" {
  count       = var.create_security_group && var.vpc_id != "" ? 1 : 0
  name        = "${local.name}-sg"
  description = var.security_group_description == "" ? "Control traffic to/from RDS ${var.engine} ${local.name}" : var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = "${local.name}-sg"
    },
  )
}

resource "aws_security_group_rule" "default_ingress" {
  count = var.create_security_group ? length(var.security_groups) : 0

  description = "For ${var.engine} cluster ${local.name} allowed ingress"

  type                     = "ingress"
  from_port                = aws_rds_cluster.main.port
  to_port                  = aws_rds_cluster.main.port
  protocol                 = "tcp"
  source_security_group_id = element(var.security_groups, count.index)
  security_group_id        = local.security_group_id
}

resource "aws_security_group_rule" "cidr_ingress" {
  count = var.create_security_group && length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  description = "RDS cluster ${local.name} ingress CIDRs"

  type              = "ingress"
  from_port         = aws_rds_cluster.main.port
  to_port           = aws_rds_cluster.main.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = local.security_group_id
}

resource "aws_security_group_rule" "egress" {
  count = var.create_security_group && var.vpc_id != "" ? 1 : 0

  description = "RDS cluster ${local.name} egress CIDRs"

  security_group_id = local.security_group_id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

# Random string to use as master password unless one is specified
resource "random_password" "master_password" {
  length  = 10
  special = false
}

# Random string to use as snapshot identifier unless one is specified
resource "random_id" "snapshot_identifier" {
  keepers = {
    id = local.name
  }

  byte_length = 4
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}
