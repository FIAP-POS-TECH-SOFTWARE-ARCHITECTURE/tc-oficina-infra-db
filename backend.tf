terraform {
  backend "s3" {
    bucket       = "tc-fiap-oficina-tfstate-931118247889"
    key          = "fase-3/infra-db.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
