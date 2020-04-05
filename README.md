# terraform-aws-vpc
Terraform module to create VPC resource on AWS.

Creates the following resources:

- VPC
- Subnet
- Nat Instance
- Route table
- Internet Gateway
- Network ACL

## Usage

```hcl
module "vpc" {
  source = "nekochans/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  nat_instance_ami         = "ami-0af1df87db7b650f4"
  nat_instance_type        = "t2.micro"
  nat_instance_volume_type = "gp2"
  nat_instance_volume_size = "30"

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
  public_subnets  = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.12.24 |
| aws | ~> 2.56 |


## Input

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name to be used on all the resources as identifier | `string` | `""` | no |
| env | The target environment | `string` | `""` | no |
| cidr | The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden | `string` | `"0.0.0.0/0"` | no |
| nat\_instance\_ami | Amazon Machine Image (AMI) for NAT Instance | `string` | `""` | no |
| nat\_instance\_type | Instance type for NAT Instance | `string` | `""` | no |
| nat\_instance\_volume\_type | Volume type for Nat Instance | `string` | `""` | no |
| nat\_instance\_volume\_size | Volume size for Nat Instance | `string` | `""` | no |
| azs | A list of availability zones names or ids in the region | `list(string)` | `[]` | no |
| public\_subnets | A list of public subnets inside the VPC | `list(string)` | `[]` | no |
| private\_subnets | A list of private subnets inside the VPC | `list(string)` | `[]` | no |

## Output

| Name | Description |
|------|-------------|
| vpc\_id | The ID of the VPC |
| subnet\_public\_ids | List of IDs of public subnets |
| subnet\_private\_ids | List of IDs of private subnets |
