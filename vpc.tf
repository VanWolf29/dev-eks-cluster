locals {
  availability_zones = [
    "${data.aws_region.current.name}a",
    "${data.aws_region.current.name}b",
    "${data.aws_region.current.name}c"
  ]
  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
  private_subnet_cidrs = [
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]
}

resource "aws_vpc" "dev_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev-vpc"
  }
}

resource "aws_internet_gateway" "dev_vpc_igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "dev-vpc-igw"
  }
}

resource "aws_subnet" "public_subnets" {
  count = 3

  availability_zone = local.availability_zones[count.index]
  cidr_block        = local.public_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.dev_vpc.id

  tags = {
    AZ                       = local.availability_zones[count.index]
    "kubernetes.io/role/elb" = 1
    Name                     = "dev-cluster-public-${local.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "private_subnets" {
  count = 3

  availability_zone = local.availability_zones[count.index]
  cidr_block        = local.private_subnet_cidrs[count.index]
  vpc_id            = aws_vpc.dev_vpc.id

  tags = {
    AZ                                  = local.availability_zones[count.index]
    "kubernetes.io/role/internal-elb"   = 1
    "kubernetes.io/cluster/dev-cluster" = "shared"
    Name                                = "dev-cluster-private-${local.availability_zones[count.index]}"
  }
}

resource "aws_eip" "dev_vpc_nat_eip" {
  tags = {
    Name = "dev-vpc-nat-eip"
  }
}

resource "aws_nat_gateway" "dev_vpc_natgw" {
  allocation_id = aws_eip.dev_vpc_nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "dev-vpc-nat-gw"
  }

  depends_on = [
    aws_internet_gateway.dev_vpc_igw
  ]
}

resource "aws_default_route_table" "public_rt" {
  default_route_table_id = aws_vpc.dev_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_vpc_igw.id
  }

  tags = {
    Name = "dev-vpc-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_associations" {
  count = 3

  route_table_id = aws_default_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnets[count.index].id

  depends_on = [
    aws_subnet.public_subnets
  ]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dev_vpc_natgw.id
  }

  tags = {
    Name = "dev-vpc-private-rt"
  }
}

resource "aws_route_table_association" "private_rt_associations" {
  count = 3

  route_table_id = aws_route_table.private_rt.id
  subnet_id      = aws_subnet.private_subnets[count.index].id

  depends_on = [
    aws_subnet.private_subnets
  ]
}
