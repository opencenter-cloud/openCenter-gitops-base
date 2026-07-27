terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket       = "000001-rax-ai"
    key          = "sandbox/tfstate/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}
