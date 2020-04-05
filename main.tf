######
# VPC
######
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "${var.env}-${var.name}-vpc"
  }
}

######
# Internet Gateway
######
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.env}-${var.name}-igw"
  }
}

################
# Nat instance
################
resource "aws_security_group" "nat_instance" {
  name        = "${var.env}-${var.name}-nat"
  description = "${var.env}-${var.name}-nat"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.env}-${var.name}-nat"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "http_from_vpc_to_nat_instance" {
  security_group_id = aws_security_group.nat_instance.id
  type              = "ingress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.this.cidr_block]
}

resource "aws_security_group_rule" "https_from_vpc_to_nat_instance" {
  security_group_id = aws_security_group.nat_instance.id
  type              = "ingress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.this.cidr_block]
}

data "aws_iam_policy_document" "nat_instance_trust_relationship" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nat_instance_role" {
  name               = "${var.env}-${var.name}-nat-instance-default-role"
  assume_role_policy = data.aws_iam_policy_document.nat_instance_trust_relationship.json
}

resource "aws_iam_role_policy_attachment" "attachment_amazon_ec2_role_for_ssm" {
  role       = aws_iam_role.nat_instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "nat_instance_profile" {
  name = "${var.env}-${var.name}-nat-instance-profile"
  role = aws_iam_role.nat_instance_role.name
}

resource "aws_instance" "nat_instance" {
  ami                         = var.nat_instance_ami
  associate_public_ip_address = true
  instance_type               = var.nat_instance_type

  ebs_block_device {
    device_name = "/dev/xvda"
    volume_type = var.nat_instance_volume_type
    volume_size = var.nat_instance_volume_size
  }

  subnet_id              = aws_subnet.public[length(var.azs) - 1].id
  vpc_security_group_ids = [aws_security_group.nat_instance.id]

  tags = {
    "Name" = format(
      "${var.env}-${var.name}-nat-%s",
      element(var.azs, length(var.azs) - 1),
    )
  }

  iam_instance_profile = aws_iam_instance_profile.nat_instance_profile.name
  monitoring           = true
  source_dest_check    = false

  lifecycle {
    ignore_changes = all
  }
}

################
# Publiс routes
################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.env}-${var.name}-public-rt"
  }
}

##########################
# Private routes
##########################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.nat_instance.id
  }

  tags = {
    Name = "${var.env}-${var.name}-private-rt"
  }
}

################
# Public subnet
################
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = element(concat(var.public_subnets, [""]), count.index)
  availability_zone = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null

  tags = {
    "Name" = format(
      "${var.env}-${var.name}-public-%s",
      element(var.azs, count.index),
    )
  }
}

#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = element(concat(var.private_subnets, [""]), count.index)
  availability_zone = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null

  tags = {
    "Name" = format(
      "${var.env}-${var.name}-private-%s",
      element(var.azs, count.index),
    )
  }
}

##########################
# Route table association
##########################

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  subnet_id = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(
    aws_route_table.public.*.id,
    count.index,
  )
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(
    aws_route_table.private.*.id,
    count.index,
  )
}

########################
# Public Network ACLs
########################
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.this.id

  ingress {
    action     = "allow"
    from_port  = 80
    protocol   = "tcp"
    rule_no    = 100
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    action     = "allow"
    from_port  = 443
    protocol   = "tcp"
    rule_no    = 110
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    action     = "allow"
    from_port  = 22
    protocol   = "tcp"
    rule_no    = 120
    to_port    = 22
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    action     = "allow"
    from_port  = 3389
    protocol   = "tcp"
    rule_no    = 130
    to_port    = 3389
    cidr_block = aws_vpc.this.cidr_block
  }

  ingress {
    action     = "allow"
    from_port  = 1024
    protocol   = "tcp"
    rule_no    = 140
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }

  egress {
    action     = "allow"
    from_port  = 80
    protocol   = "tcp"
    rule_no    = 100
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }

  egress {
    action     = "allow"
    from_port  = 443
    protocol   = "tcp"
    rule_no    = 110
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }

  egress {
    action     = "allow"
    from_port  = 3306
    protocol   = "tcp"
    rule_no    = 120
    to_port    = 3306
    cidr_block = aws_vpc.this.cidr_block
  }

  egress {
    action     = "allow"
    from_port  = 1024
    protocol   = "tcp"
    rule_no    = 130
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }

  egress {
    action     = "allow"
    from_port  = 22
    protocol   = "tcp"
    rule_no    = 140
    to_port    = 22
    cidr_block = "0.0.0.0/0"
  }

  subnet_ids = aws_subnet.public.*.id

  tags = {
    Name = "${var.env}-${var.name}-public"
  }
}

#######################
# Private Network ACLs
#######################
resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.this.id

  ingress {
    action     = "allow"
    from_port  = 80
    protocol   = "tcp"
    rule_no    = 100
    to_port    = 80
    cidr_block = aws_vpc.this.cidr_block
  }

  ingress {
    action     = "allow"
    from_port  = 443
    protocol   = "tcp"
    rule_no    = 110
    to_port    = 443
    cidr_block = aws_vpc.this.cidr_block
  }

  ingress {
    action     = "allow"
    from_port  = 22
    protocol   = "tcp"
    rule_no    = 120
    to_port    = 22
    cidr_block = aws_vpc.this.cidr_block
  }

  ingress {
    action     = "allow"
    from_port  = 3306
    protocol   = "tcp"
    rule_no    = 130
    to_port    = 3306
    cidr_block = aws_vpc.this.cidr_block
  }

  ingress {
    action     = "allow"
    from_port  = 3389
    protocol   = "tcp"
    rule_no    = 140
    to_port    = 3389
    cidr_block = aws_vpc.this.cidr_block
  }

  ingress {
    action     = "allow"
    from_port  = 1024
    protocol   = "tcp"
    rule_no    = 150
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }

  egress {
    action     = "allow"
    from_port  = 80
    protocol   = "tcp"
    rule_no    = 100
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }

  egress {
    action     = "allow"
    from_port  = 443
    protocol   = "tcp"
    rule_no    = 110
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }

  egress {
    action     = "allow"
    from_port  = 1024
    protocol   = "tcp"
    rule_no    = 120
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }

  egress {
    action     = "allow"
    from_port  = 22
    protocol   = "tcp"
    rule_no    = 130
    to_port    = 22
    cidr_block = "0.0.0.0/0"
  }

  subnet_ids = aws_subnet.private.*.id

  tags = {
    Name = "${var.env}-${var.name}-private"
  }
}
