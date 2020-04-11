provider "aws" {
  region = "ap-northeast-1"
}

module "vpc" {
  source = "../../"

  name = "vpc-example"

  env = "dev"

  cidr = "10.10.0.0/16"

  nat_instance_ami         = "ami-0af1df87db7b650f4"
  nat_instance_type        = "t2.micro"
  nat_instance_volume_type = "gp2"
  nat_instance_volume_size = "30"

  azs = [
    "ap-northeast-1a",
    "ap-northeast-1c",
    "ap-northeast-1d"
  ]

  public_subnets = [
    "10.10.0.0/24",
    "10.10.1.0/24",
    "10.10.2.0/24"
  ]

  private_subnets = [
    "10.10.10.0/24",
    "10.10.11.0/24",
    "10.10.12.0/24"
  ]
}
