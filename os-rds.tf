# Instância PostgreSQL do os-service (bancos oficina_homolog e oficina_prod).
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db"
  engine                 = "postgres"
  engine_version         = "18"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  db_name                = "postgres"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
  apply_immediately      = true

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }

  lifecycle {
    # Qualquer plan que destrua ou recrie esta instância falha em vez de
    # apagar os dados. Para destruir de propósito, remover este bloco num PR.
    prevent_destroy = true
  }
}
