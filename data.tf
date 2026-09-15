data "terraform_remote_state" "k8s" {
  backend = "s3"
  config = {
    bucket = "tc-fiap-oficina-tfstate-512135631497"
    key    = "fase-3/infra-k8s.tfstate"
    region = "us-east-1"
  }
}
