# Rede compartilhada pelas instâncias RDS (os-service e execution-service):
# mesmas subnets públicas e mesma regra de acesso. O isolamento entre os
# serviços é por instância e por credencial, não por rede.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = data.terraform_remote_state.k8s.outputs.public_subnet_ids

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
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

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}
