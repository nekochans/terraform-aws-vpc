variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "env" {
  description = "The target environment"
  type        = string
  default     = ""
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "0.0.0.0/0"
}

variable "nat_instance_ami" {
  description = "Amazon Machine Image (AMI) for NAT Instance"
  type        = string
  default     = ""
}

variable "nat_instance_type" {
  description = "Instance type for NAT Instance"
  type        = string
  default     = ""
}

variable "nat_instance_volume_type" {
  description = "Volume type for Nat Instance"
  type        = string
  default     = ""
}

variable "nat_instance_volume_size" {
  description = "Volume size for Nat Instance"
  type        = string
  default     = ""
}

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}
