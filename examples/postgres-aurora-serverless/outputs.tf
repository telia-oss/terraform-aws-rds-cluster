output "id" {
  description = "The ID of the cluster"
  value       = module.rds.id
}

output "arn" {
  description = "The Resource ID of the cluster"
  value       = module.rds.arn
}

output "endpoint" {
  description = "The cluster endpoint"
  value       = module.rds.endpoint
}

output "database_name" {
  description = "Name for an automatically created database on cluster creation"
  value       = module.rds.database_name
}

output "port" {
  description = "The port"
  value       = module.rds.port
}

output "username" {
  description = "The master username"
  value       = module.rds.username
}
