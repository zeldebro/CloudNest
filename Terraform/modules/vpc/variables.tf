variable "project" {
  description = "Project name"
  type        = string
}
variable "region" {
  description = "AWS region"
  type        = string
}
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}
variable "vpc_cidr_block" {
  description = "CIDR block for the development VPC"
  type        = string
}
variable "public_subnet_cidr_block" {
  description = "CIDR block for the public subnet in the development VPC"
  type        = map(string)
}
variable "cloudnest_eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}
variable "private_subnet_cidr_block" {
  description = "CIDR block for the private subnet in the development VPC"
  type        = map(string)
}
variable "flow_log_destination_arn" {
  description = "ARN of the CloudWatch Log Group for VPC flow logs"
  type        = string
}
variable "flow_log_role_arn" {
  description = "ARN of the IAM role for VPC flow logs"
  type        = string
}
