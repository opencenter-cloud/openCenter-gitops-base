

## Local backend
terraform {
  backend "local" {
    path = ".dev.tfstate"
  }
}
## S3 Backend
# terraform {
#   backend "s3" {
#     bucket       = "<REPLACE_BUCKET_NAME>"
#     key          = "<REPLACE_CLUSTER_NAME>/tfstate/terraform.tfstate"
#     region       = "<REPLACE_REGION>"
#     use_lockfile = true
#     encrypt      = true
#   }
# }
