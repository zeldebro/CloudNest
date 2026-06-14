# This module creates a VPC in AWS. It can be used to create a new VPC or to manage an existing one.
resource "aws_vpc" "cloudenest_dev_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

# Public subnet
resource "aws_subnet" "cloudnest_public_subnet" {
  for_each                = var.public_subnet_cidr_block
  vpc_id                  = aws_vpc.cloudenest_dev_vpc.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true
  tags = {
    Name                                                      = "${var.project}-${var.environment}-public-subnet-${each.key}"
    "kubernetes.io/role/elb"                                  = "1"
    "kubernetes.io/cluster/${var.cloudnest_eks_cluster_name}" = "shared"

  }
}

# Internet Gateway
resource "aws_internet_gateway" "cloudenest_igw" {
  vpc_id = aws_vpc.cloudenest_dev_vpc.id
  tags = {
    Name = "${var.project}-${var.environment}-igw"
  }
}

#public route tabel
resource "aws_route_table" "cloudenest_public_rt" {
  vpc_id = aws_vpc.cloudenest_dev_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudenest_igw.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-public-rt"
  }
}

# Associate public subnet with route table
resource "aws_route_table_association" "cloudenest_public_rt_assoc" {
  for_each       = aws_subnet.cloudnest_public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.cloudenest_public_rt.id
}



# private subnet
resource "aws_subnet" "cloudenest_private_subnet" {
  for_each                = var.private_subnet_cidr_block
  vpc_id                  = aws_vpc.cloudenest_dev_vpc.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false
  tags = {
    Name                                                      = "${var.project}-${var.environment}-private-subnet-${each.key}"
    "kubernetes.io/role/internal-elb"                         = "1"
    "kubernetes.io/cluster/${var.cloudnest_eks_cluster_name}" = "shared"
    # Karpenter discovers WHERE to launch nodes by this tag
    "karpenter.sh/discovery" = var.cloudnest_eks_cluster_name
  }
}


# Elastic IP for NAT Gateway
resource "aws_eip" "cloudenest_nat_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.project}-${var.environment}-nat-eip"
  }
}

#nat gateway (single NAT for all AZs - cost-optimized; trade-off: AZ-level SPOF + cross-AZ data charges)
resource "aws_nat_gateway" "cloudenest_nat_gw" {
  subnet_id     = aws_subnet.cloudnest_public_subnet["us-east-1a"].id
  allocation_id = aws_eip.cloudenest_nat_eip.id
  tags = {
    Name = "${var.project}-${var.environment}-nat-gw"
  }
}
# Private Route table
resource "aws_route_table" "cloudenest_private_rt" {
  vpc_id = aws_vpc.cloudenest_dev_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cloudenest_nat_gw.id
  }
  tags = {
    Name = "${var.project}-${var.environment}-private-rt"
  }
}
# Associate private subnet with route table
resource "aws_route_table_association" "cloudenest_private_rt_assoc" {
  for_each       = aws_subnet.cloudenest_private_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.cloudenest_private_rt.id
}

# =========================================================
# Lock down the AWS-created "default" resources.
# AWS auto-creates a default Security Group and Route Table with every new VPC.
# They cannot be deleted, but leaving the default SG open (allow-all) is a CIS
# finding (AWS 4.3). We ADOPT them into state and strip every rule so nothing
# can ever use them. All real traffic flows through our explicit
# subnets/route tables/security groups instead. (Default NACL left untouched.)
# =========================================================

# Default Security Group: no ingress, no egress (deny-all).
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.cloudenest_dev_vpc.id
  # No ingress / egress blocks = all rules removed.
  tags = {
    Name = "${var.project}-${var.environment}-default-sg-DO-NOT-USE"
  }
}

# Default Route Table: kept empty (no routes), only tagged for visibility.
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.cloudenest_dev_vpc.default_route_table_id
  tags = {
    Name = "${var.project}-${var.environment}-default-rt-DO-NOT-USE"
  }
}


# VPC flow logs (log group + IAM role come from the cloudwatch module, passed in as variables)
resource "aws_flow_log" "cloudnest_vpc_flow_log" {
  log_destination      = var.flow_log_destination_arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = var.flow_log_role_arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.cloudenest_dev_vpc.id
  tags = {
    Name = "${var.project}-${var.environment}-vpc-flow-log"
  }
}




