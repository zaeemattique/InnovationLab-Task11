resource "aws_vpc" "Task11-VPC-Zaeem" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "Task11-VPC-Zaeem"
  }
  
}

resource "aws_internet_gateway" "Task11-IGW-Zaeem" {
  vpc_id = aws_vpc.Task11-VPC-Zaeem.id

  tags = {
    Name = "Task11-IGW-Zaeem"
  }
  
}

resource "aws_eip" "Task11-NAT-A-EIP-Zaeem" {

  tags = {
    Name = "Task11-NAT-A-EIP-Zaeem"
  }
  
}

resource "aws_nat_gateway" "Task11-NAT-A-Zaeem" {
   allocation_id = aws_eip.Task11-NAT-A-EIP-Zaeem.id
  subnet_id     = aws_subnet.Task11-Public-Subnet-A-Zaeem.id

  tags = {
    Name = "Task11-NAT-A-Zaeem"
  }
  
}

resource "aws_eip" "Task11-NAT-B-EIP-Zaeem" {

  tags = {
    Name = "Task11-NAT-B-EIP-Zaeem"
  }
  
}

resource "aws_nat_gateway" "Task11-NAT-B-Zaeem" {
   allocation_id = aws_eip.Task11-NAT-B-EIP-Zaeem.id
  subnet_id     = aws_subnet.Task11-Public-Subnet-B-Zaeem.id

  tags = {
    Name = "Task11-NAT-B-Zaeem"
  }
  
}

resource "aws_subnet" "Task11-Public-Subnet-A-Zaeem" {
  vpc_id            = aws_vpc.Task11-VPC-Zaeem.id
  cidr_block        = var.public_subnetA_cidr
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Task11-Public-Subnet-A-Zaeem"
  }
  
}

resource "aws_subnet" "Task11-Public-Subnet-B-Zaeem" {
  vpc_id            = aws_vpc.Task11-VPC-Zaeem.id
  cidr_block        = var.public_subnetB_cidr
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Task11-Public-Subnet-B-Zaeem"
  }
  
}

resource "aws_subnet" "Task11-Private-Subnet-A-Zaeem" {
  vpc_id            = aws_vpc.Task11-VPC-Zaeem.id
  cidr_block        = var.private_subnetA_cidr
  availability_zone = "us-west-2a"

  tags = {
    Name = "Task11-Private-Subnet-A-Zaeem"
  }
  
}

resource "aws_subnet" "Task11-Private-Subnet-B-Zaeem" {
  vpc_id            = aws_vpc.Task11-VPC-Zaeem.id
  cidr_block        = var.private_subnetB_cidr
  availability_zone = "us-west-2b"

  tags = {
    Name = "Task11-Private-Subnet-B-Zaeem"
  }
  
}

resource "aws_route_table" "Public-RT-Zaeem" {
  vpc_id = aws_vpc.Task11-VPC-Zaeem.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Task11-IGW-Zaeem.id
  }

  tags = {
    Name = "Public-RT-Zaeem"
  }
  
}

resource "aws_route_table_association" "Public-RT-Assoc-A-Zaeem" {
  subnet_id      = aws_subnet.Task11-Public-Subnet-A-Zaeem.id
  route_table_id = aws_route_table.Public-RT-Zaeem.id
  
}

resource "aws_route_table_association" "Public-RT-Assoc-B-Zaeem" {
  subnet_id      = aws_subnet.Task11-Public-Subnet-B-Zaeem.id
  route_table_id = aws_route_table.Public-RT-Zaeem.id
  
}

resource "aws_route_table" "Private-RT-A-Zaeem" {
  vpc_id = aws_vpc.Task11-VPC-Zaeem.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Task11-NAT-A-Zaeem.id
  }

  tags = {
    Name = "Private-RT-A-Zaeem"
  }
  
}

resource "aws_route_table" "Private-RT-B-Zaeem" {
  vpc_id = aws_vpc.Task11-VPC-Zaeem.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Task11-NAT-B-Zaeem.id
  }

  tags = {
    Name = "Private-RT-B-Zaeem"
  }
  
}

resource "aws_route_table_association" "Private-RT-Assoc-A-Zaeem" {
  subnet_id      = aws_subnet.Task11-Private-Subnet-A-Zaeem.id
  route_table_id = aws_route_table.Private-RT-A-Zaeem.id
  
}

resource "aws_route_table_association" "Private-RT-Assoc-B-Zaeem" {
  subnet_id      = aws_subnet.Task11-Private-Subnet-B-Zaeem.id
  route_table_id = aws_route_table.Private-RT-B-Zaeem.id
  
}

resource "aws_security_group" "Task11-ALB-SG-Zaeem" {
  name        = "Task11-alb-sg-zaeem"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.Task11-VPC-Zaeem.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Task11-alb-sg-zaeem"
  }
}

# EC2 Instances Security Group
resource "aws_security_group" "Task11-EC2-SG-Zaeem" {
  name        = "Task11-ec2-sg-zaeem"
  description = "Security group for ECS EC2 instances"
  vpc_id      = aws_vpc.Task11-VPC-Zaeem.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.Task11-ALB-SG-Zaeem.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Task11-ec2-sg-zaeem"
  }
}

# EFS Security Group
resource "aws_security_group" "Task11-EFS-SG-Zaeem" {
  name        = "Task11-efs-sg-zaeem"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.Task11-VPC-Zaeem.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.Task11-EC2-SG-Zaeem.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Task11-efs-sg-zaeem"
  }
}
