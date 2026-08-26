data "terraform_remote_state" "k8s" {
  backend = "s3"
  config = {
    bucket = "tc-fiap-oficina-tfstate-076155200589"
    key    = "fase-3/infra-k8s.tfstate"
    region = "us-east-1"
  }
}
