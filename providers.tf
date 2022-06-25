
terraform {
  required_version = ">=1.1.5"

  backend "s3" {
    bucket         = "ec2-kojitechs-registrationapps-tf-12"
    dynamodb_table = "terraform-lock"
    key            = "path/env"
    region         = "us-east-1"
    encrypt        = "true"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# service role. 
# read, s3, buck, 
provider "aws" {
  region = var.region # 

  # assume_role {
  #   role_arn = "arn:aws:iam::${lookup(var.env, terraform.workspace)}:role/Terraform_Admin_Role"
  # }
  default_tags {
    tags = local.mandatory_tag
  }
}
