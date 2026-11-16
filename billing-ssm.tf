# Nome da tabela do billing-service (lido pelo CD do billing-service).
resource "aws_ssm_parameter" "billing_dynamodb_table" {
  for_each = toset(var.environments)

  name  = "/${var.project_name}/${each.key}/billing/dynamodb-table"
  type  = "String"
  value = aws_dynamodb_table.billing[each.key].name
}
