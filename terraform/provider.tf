##########################################
# provider.tf
##########################################

provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "devops-tfstate-bucket-manikanta"
    key    = "ec2-project/terraform.tfstate"
    region = "ap-southeast-1"
    encrypt = true
  }
}
