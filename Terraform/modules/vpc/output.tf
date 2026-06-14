output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.cloudenest_dev_vpc.id
}
output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [for subnet in aws_subnet.cloudnest_public_subnet : subnet.id]
}
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.cloudenest_dev_vpc.cidr_block
}
output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = [for subnet in aws_subnet.cloudenest_private_subnet : subnet.id]
}
output "nat_gateway_id" {
  description = "The ID of the NAT gateway"
  value       = aws_nat_gateway.cloudenest_nat_gw.id
}