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

# Chave dos endpoints internos serviço→serviço (header x-internal-api-key).
resource "random_password" "internal_api_key" {
  for_each = toset(var.environments)
  length   = 48
  special  = false
}

resource "aws_ssm_parameter" "internal_api_key" {
  for_each = toset(var.environments)

  name  = "/${var.project_name}/${each.key}/internal-api-key"
  type  = "SecureString"
  value = random_password.internal_api_key[each.key].result
}
