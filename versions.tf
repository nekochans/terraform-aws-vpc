terraform {
  required_version = ">= 0.14.0, < 0.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.56"
    }
  }
}
