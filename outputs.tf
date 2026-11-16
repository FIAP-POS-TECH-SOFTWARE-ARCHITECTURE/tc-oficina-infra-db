output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "databases" {
  value = [for db in postgresql_database.env : db.name]
}

output "execution_db_endpoint" {
  value = aws_db_instance.execution.address
}

output "execution_databases" {
  value = [for db in postgresql_database.execution : db.name]
}

output "billing_dynamodb_tables" {
  value = [for tabela in aws_dynamodb_table.billing : tabela.name]
}
