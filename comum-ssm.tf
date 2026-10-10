# Segredos compartilhados entre serviços, por ambiente.

# Assina/valida os JWTs (staff e cliente) em todos os serviços e na Lambda.
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
