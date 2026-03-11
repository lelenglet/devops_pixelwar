terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.34"
    }
  }
}

provider "aws" {
    region = "us-west-2"
}
