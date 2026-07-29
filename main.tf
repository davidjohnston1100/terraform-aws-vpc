resource "aws_vpc" "this" {
  cidr_block                           = var.vpc_cidr
  enable_dns_support                   = var.enable_dns_support
  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics

  tags = merge(
    local.common_tags,
    var.vpc_tags,
    {
      Name = "${var.name}-vpc"
    }
  )

  lifecycle {
    precondition {
      condition     = !var.enable_dns_hostnames || var.enable_dns_support
      error_message = "enable_dns_support must be true when enable_dns_hostnames is true."
    }
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

resource "aws_subnet" "public" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value.public_cidr
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    local.common_tags,
    var.public_subnet_tags,
    {
      Name                          = "${var.name}-public-${each.key}"
      "stratovio:subnet-tier"       = "public"
      "stratovio:availability-zone" = each.key
    }
  )
}

resource "aws_subnet" "private" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value.private_cidr
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    var.private_subnet_tags,
    {
      Name                          = "${var.name}-private-${each.key}"
      "stratovio:subnet-tier"       = "private"
      "stratovio:availability-zone" = each.key
    }
  )
}

resource "aws_subnet" "database" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value.database_cidr
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    var.database_subnet_tags,
    {
      Name                          = "${var.name}-database-${each.key}"
      "stratovio:subnet-tier"       = "database"
      "stratovio:availability-zone" = each.key
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-public-rt"
    }
  )
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = local.nat_gateway_azs

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-nat-eip-${each.key}"
    }
  )
}

resource "aws_nat_gateway" "this" {
  for_each = local.nat_gateway_azs

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-nat-${each.key}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = var.subnets

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-private-rt-${each.key}"
    }
  )
}

resource "aws_route" "private_default" {
  for_each = local.private_nat_gateway_az_by_az

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value].id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table" "database" {
  for_each = var.subnets

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-database-rt-${each.key}"
    }
  )
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[each.key].id
}

resource "aws_db_subnet_group" "this" {
  count = var.create_database_subnet_group ? 1 : 0

  name        = coalesce(var.database_subnet_group_name, "${var.name}-database")
  description = "Database subnets for ${var.name}"
  subnet_ids  = [for az in local.availability_zones : aws_subnet.database[az].id]

  tags = merge(
    local.common_tags,
    {
      Name = coalesce(var.database_subnet_group_name, "${var.name}-database")
    }
  )
}

resource "aws_default_security_group" "this" {
  count = var.manage_default_security_group ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-default-deny-all"
    }
  )
}
