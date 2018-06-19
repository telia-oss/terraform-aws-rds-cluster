# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "id" {
  description = "The RDS Cluster Identifier."
  value       = "${aws_rds_cluster.main.id}"
}

output "endpoint" {
  description = "The DNS address of the RDS instance."
  value       = "${aws_rds_cluster.main.endpoint}"
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string."
  value       = "postgres://${var.username}:${var.password}@${aws_rds_cluster.main.endpoint}:${var.port}/${var.database_name}"
}

output "port" {
  description = "The port on which the DB accepts connections."
  value       = "${aws_rds_cluster.main.port}"
}

output "database_name" {
  description = "Name for the automatically created database."
  value       = "${aws_rds_cluster.main.database_name}"
}

output "security_group_id" {
  description = "The ID of the security group."
  value       = "${aws_security_group.main.id}"
}

output "subnet_group_id" {
  description = "The db subnet group name."
  value       = "${aws_db_subnet_group.main.id}"
}

output "subnet_group_arn" {
  description = "The ARN of the db subnet group."
  value       = "${aws_db_subnet_group.main.arn}"
}
