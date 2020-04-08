# VPC
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

# Subnets
output "subnet_public_ids" {
  value       = module.vpc.subnet_public_ids
  description = "List of IDs of public subnets"
}

output "subnet_private_ids" {
  value       = module.vpc.subnet_private_ids
  description = "List of IDs of private subnets"
}
