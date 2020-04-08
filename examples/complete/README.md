# Complete VPC

Configuration in this directory creates set of VPC resources with Nat Instance.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## Requirements

No requirements.

## Providers

No provider.

## Inputs

No input.

## Outputs

| Name | Description |
|------|-------------|
| subnet\_private\_ids | List of IDs of private subnets |
| subnet\_public\_ids | List of IDs of public subnets |
| vpc\_id | The ID of the VPC |
