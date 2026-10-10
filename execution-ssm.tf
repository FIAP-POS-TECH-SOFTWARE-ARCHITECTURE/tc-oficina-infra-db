# Connection string do execution-service (lida pelo CD do execution-service).
resource "aws_ssm_parameter" "execution_database_url" {
  for_each = toset(var.environments)

  name = "/${var.project_name}/${each.key}/execution/database-url"
  type = "SecureString"
  value = format(
    "postgresql://%s:%s@%s:5432/%s?schema=public&sslmode=no-verify",
    var.execution_db_username,
    urlencode(random_password.execution_db.result),
    aws_db_instance.execution.address,
    postgresql_database.execution[each.key].name,
  )
}
