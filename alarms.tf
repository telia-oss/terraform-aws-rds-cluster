
# -------------------------------------------------------------------------------
# Resources
# -------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alarm_rds_DatabaseConnections_writer" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${aws_rds_cluster.main.id}-alarm-rds-writer-DatabaseConnections"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.cloudwatch_eval_period_connections
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Sum"
  threshold           = var.cloudwatch_max_conns
  alarm_description   = "RDS Maximum connection Alarm for ${aws_rds_cluster.main.id} writer"
  alarm_actions       = [var.cloudwatch_sns_topic]
  ok_actions          = [var.cloudwatch_sns_topic]

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.id
    Role                = "WRITER"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_rds_CPU_writer" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${aws_rds_cluster.main.id}-alarm-rds-writer-CPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.cloudwatch_eval_period_cpu
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = var.cloudwatch_max_cpu
  alarm_description   = "RDS CPU Alarm for ${aws_rds_cluster.main.id} writer"
  alarm_actions       = ["${var.cloudwatch_sns_topic}"]
  ok_actions          = ["${var.cloudwatch_sns_topic}"]

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.id
    Role                = "WRITER"
  }
}

/*
resource "aws_db_event_subscription" "default" {
  name      = "${aws_rds_cluster.main.id}-rds-event-sub"
  sns_topic = var.cloudwatch_sns_topic

  source_type = "db-instance"
  source_ids  = ["${aws_db_instance.default.id}"]

  event_categories = [
    "availability",
    "deletion",
    "failover",
    "failure",
    "low storage",
    "maintenance",
    "notification",
    "read replica",
    "recovery",
    "restoration",
  ]
}
*/
