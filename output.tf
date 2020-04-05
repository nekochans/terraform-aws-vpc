output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the VPC"
}

output "subnet_public_ids" {
  value       = aws_subnet.public.*.id
  description = "List of IDs of public subnets"
}

output "subnet_private_ids" {
  value       = aws_subnet.private.*.id
  description = "List of IDs of private subnets"
}
