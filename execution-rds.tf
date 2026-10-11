# Instância PostgreSQL exclusiva do execution-service (fila de diagnóstico e
# reparo). Reaproveita a rede do RDS do os-service; credencial própria.

# Só alfanumérico: evita caracteres que o RDS recusa (/ @ " espaço) e
# problemas de escape na connection string.
resource "random_password" "execution_db" {
  length  = 32
  special = false
}

resource "aws_db_instance" "execution" {
  identifier             = "${var.project_name}-execution-db"
  engine                 = "postgres"
  engine_version         = "18"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_encrypted      = true
  db_name                = "postgres"
  username               = var.execution_db_username
  password               = random_password.execution_db.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
  apply_immediately      = true

  tags = {
    Project   = var.project_name
    Servico   = "execution-service"
    ManagedBy = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}
