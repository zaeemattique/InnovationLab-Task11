output "private_subnetA_id" {
  value = aws_subnet.Task11-Private-Subnet-A-Zaeem.id
}

output "private_subnetB_id" {
  value = aws_subnet.Task11-Private-Subnet-B-Zaeem.id
}

output "public_subnetA_id" {
  value = aws_subnet.Task11-Public-Subnet-A-Zaeem.id
}
output "public_subnetB_id" {
  value = aws_subnet.Task11-Public-Subnet-B-Zaeem.id
}

output "vpc_id" {
  value = aws_vpc.Task11-VPC-Zaeem.id
}

output "instance_security_group_id" {
  value = aws_security_group.Task11-EC2-SG-Zaeem.id
}

output "alb_security_group_id" {
  value = aws_security_group.Task11-ALB-SG-Zaeem.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.Task11-Public-Subnet-A-Zaeem.id,
    aws_subnet.Task11-Public-Subnet-B-Zaeem.id
  ]
}

output "private_subnet_ids" {
  value = [
    aws_subnet.Task11-Private-Subnet-A-Zaeem.id,
    aws_subnet.Task11-Private-Subnet-B-Zaeem.id
  ]
}