# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "id" {
  description = "The RDS Cluster Identifier."
  value       = "${aws_rds_cluster.main.id}"
}

output "resource_id" {
  description = "The RDS Cluster Resource ID."
  value       = "${aws_rds_cluster.main.cluster_resource_id}"
}

output "arn" {
  description = "Amazon Resource Name (ARN) of cluster."
  value       = "${aws_rds_cluster.main.arn}"
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

output "endpoint" {
  description = "The DNS address of the RDS instance."
  value       = "${aws_rds_cluster.main.endpoint}"
}

output "port" {
  description = "The database port."
  value       = "${aws_rds_cluster.main.port}"
}

output "username" {
  description = "The master username for the database."
  value       = "${aws_rds_cluster.main.master_username}"
}

output "database_name" {
  description = "Name for the automatically created database."
  value       = "${aws_rds_cluster.main.database_name}"
}
