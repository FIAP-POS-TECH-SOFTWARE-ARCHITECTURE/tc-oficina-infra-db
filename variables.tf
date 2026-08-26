variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "oficina"
}

variable "db_username" {
  type    = string
  default = "oficina"
}

variable "db_password" {
  type      = string
  sensitive = true
  # sem default: vem de TF_VAR_db_password (secret do repositório)
}

variable "environments" {
  type    = list(string)
  default = ["homolog", "prod"]
}
