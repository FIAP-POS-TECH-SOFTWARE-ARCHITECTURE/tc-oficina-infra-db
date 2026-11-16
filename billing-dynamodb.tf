# Tabela única por ambiente do billing-service (orçamentos, pagamentos e
# controle de mensagens processadas), acesso por chave + índice gsi1.
resource "aws_dynamodb_table" "billing" {
  for_each = toset(var.environments)

  name         = "${var.project_name}-billing-${each.key}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "gsi1pk"
    type = "S"
  }

  attribute {
    name = "gsi1sk"
    type = "S"
  }

  global_secondary_index {
    name            = "gsi1"
    hash_key        = "gsi1pk"
    range_key       = "gsi1sk"
    projection_type = "ALL"
  }

  # Sandbox acadêmico: dados recriáveis; backup contínuo desligado.
  point_in_time_recovery {
    enabled = false
  }

  tags = {
    Project   = var.project_name
    Servico   = "billing-service"
    ManagedBy = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}
