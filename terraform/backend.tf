terraform {
  backend "s3" {
    bucket         = "asdfaasds3244322esssassaf"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    use_lockfile = true
  }
}