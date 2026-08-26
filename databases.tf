resource "postgresql_database" "env" {
  for_each = toset(var.environments)

  name  = "${var.project_name}_${each.key}"
  owner = var.db_username
}
