terraform {
  backend "s3" {
    bucket         = "contractor-lens-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "contractor-lens-terraform-locks"
  }
}
