resource "postgresql_database" "execution" {
  provider = postgresql.execution
  for_each = toset(var.environments)

  name  = "execution_${each.key}"
  owner = var.execution_db_username
}
