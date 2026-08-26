resource "random_password" "jwt" {
  for_each = toset(var.environments)
  length   = 64
  special  = false
}

resource "aws_ssm_parameter" "jwt_secret" {
  for_each = toset(var.environments)

  name  = "/${var.project_name}/${each.key}/jwt-secret"
  type  = "SecureString"
  value = random_password.jwt[each.key].result
}

resource "aws_ssm_parameter" "database_url" {
  for_each = toset(var.environments)

  name = "/${var.project_name}/${each.key}/database-url"
  type = "SecureString"
  value = format(
    "postgresql://%s:%s@%s:5432/%s?schema=public",
    var.db_username,
    urlencode(var.db_password),
    aws_db_instance.main.address,
    postgresql_database.env[each.key].name,
  )
}
