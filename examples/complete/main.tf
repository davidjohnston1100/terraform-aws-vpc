module "vpc" {
  source = "../.."

  name     = "stratovio-prod"
  vpc_cidr = "10.20.0.0/16"

  subnets = {
    us-east-2a = {
      public_cidr   = "10.20.0.0/24"
      private_cidr  = "10.20.10.0/24"
      database_cidr = "10.20.20.0/24"
    }
    us-east-2b = {
      public_cidr   = "10.20.1.0/24"
      private_cidr  = "10.20.11.0/24"
      database_cidr = "10.20.21.0/24"
    }
    us-east-2c = {
      public_cidr   = "10.20.2.0/24"
      private_cidr  = "10.20.12.0/24"
      database_cidr = "10.20.22.0/24"
    }
  }

  nat_gateway_mode                     = "per_az"
  enable_flow_logs                     = true
  flow_log_retention_in_days           = 90
  manage_default_security_group        = true
  create_database_subnet_group         = true
  map_public_ip_on_launch              = false
  enable_network_address_usage_metrics = true

  tags = {
    Company     = "Stratovio Technologies"
    Environment = "production"
    CostCenter  = "shared-networking"
  }
}
