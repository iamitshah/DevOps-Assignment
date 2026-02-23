terraform {
  backend "s3" {
    bucket       = "testingproject-tfstate-aps1-amit-001"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
