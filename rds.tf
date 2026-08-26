resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = data.terraform_remote_state.k8s.outputs.public_subnet_ids
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = data.terraform_remote_state.k8s.outputs.vpc_id

  # Postgres a partir da VPC (pods do EKS)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.k8s.outputs.vpc_cidr_block]
  }

  # TRADE-OFF ACADEMY (documentado no README): acesso externo para
  # migração via pipeline, provider postgresql e Lambda fora da VPC.
  # Produção real: apenas VPC + bastion.
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db"
  engine                 = "postgres"
  engine_version         = "18"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "postgres"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
  apply_immediately      = true
}
