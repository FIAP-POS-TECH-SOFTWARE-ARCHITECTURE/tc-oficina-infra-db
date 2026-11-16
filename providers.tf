terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.25"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Conecta no RDS público do os-service (trade-off Academy documentado no
# README) para criar os bancos lógicos de homolog e prod.
provider "postgresql" {
  host      = aws_db_instance.main.address
  port      = 5432
  username  = var.db_username
  password  = var.db_password
  sslmode   = "require"
  superuser = false
}

# Mesma ideia, na instância própria do execution-service.
provider "postgresql" {
  alias     = "execution"
  host      = aws_db_instance.execution.address
  port      = 5432
  username  = var.execution_db_username
  password  = random_password.execution_db.result
  sslmode   = "require"
  superuser = false
}
