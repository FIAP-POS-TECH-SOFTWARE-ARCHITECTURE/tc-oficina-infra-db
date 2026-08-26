output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "databases" {
  value = [for db in postgresql_database.env : db.name]
}
