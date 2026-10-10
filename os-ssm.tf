# Connection string do os-service (lida pelo CD do os-service).
resource "aws_ssm_parameter" "database_url" {
  for_each = toset(var.environments)

  name = "/${var.project_name}/${each.key}/database-url"
  type = "SecureString"
  value = format(
    "postgresql://%s:%s@%s:5432/%s?schema=public&sslmode=no-verify",
    var.db_username,
    urlencode(var.db_password),
    aws_db_instance.main.address,
    postgresql_database.env[each.key].name,
  )
}
