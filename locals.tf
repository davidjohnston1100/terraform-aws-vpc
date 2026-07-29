locals {
  availability_zones = sort(keys(var.subnets))
  primary_az         = local.availability_zones[0]

  common_tags = merge(
    {
      ManagedBy = "Terraform"
      Module    = "stratovio-aws-vpc"
    },
    var.tags
  )

  nat_gateway_azs = var.nat_gateway_mode == "none" ? toset([]) : (
    var.nat_gateway_mode == "single" ? toset([local.primary_az]) : toset(local.availability_zones)
  )

  # Maps each private subnet AZ to the AZ containing its NAT gateway.
  private_nat_gateway_az_by_az = var.nat_gateway_mode == "none" ? {} : {
    for az in local.availability_zones :
    az => var.nat_gateway_mode == "single" ? local.primary_az : az
  }
}
