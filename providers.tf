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

# Conecta no RDS público (trade-off Academy documentado no README)
# para criar os bancos lógicos de homolog e prod.
provider "postgresql" {
  host      = aws_db_instance.main.address
  port      = 5432
  username  = var.db_username
  password  = var.db_password
  sslmode   = "require"
  superuser = false
}
