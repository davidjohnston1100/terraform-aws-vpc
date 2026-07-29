mock_provider "aws" {}

run "per_az_nat_creates_three_tiers" {
  command = plan

  variables {
    name     = "stratovio-test"
    vpc_cidr = "10.30.0.0/16"

    subnets = {
      us-east-2a = {
        public_cidr   = "10.30.0.0/24"
        private_cidr  = "10.30.10.0/24"
        database_cidr = "10.30.20.0/24"
      }
      us-east-2b = {
        public_cidr   = "10.30.1.0/24"
        private_cidr  = "10.30.11.0/24"
        database_cidr = "10.30.21.0/24"
      }
      us-east-2c = {
        public_cidr   = "10.30.2.0/24"
        private_cidr  = "10.30.12.0/24"
        database_cidr = "10.30.22.0/24"
      }
    }
  }

  assert {
    condition     = length(output.public_subnet_ids) == 3
    error_message = "Expected one public subnet in each Availability Zone."
  }

  assert {
    condition     = length(output.private_subnet_ids) == 3
    error_message = "Expected one private subnet in each Availability Zone."
  }

  assert {
    condition     = length(output.database_subnet_ids) == 3
    error_message = "Expected one database subnet in each Availability Zone."
  }

  assert {
    condition     = length(output.nat_gateway_ids) == 3
    error_message = "per_az mode must create one NAT gateway in each Availability Zone."
  }

  assert {
    condition     = output.database_subnet_group_name == "stratovio-test-database"
    error_message = "Expected the default database subnet group name."
  }

  assert {
    condition     = output.flow_log_id == null
    error_message = "Flow logs should be disabled by default."
  }
}

run "single_nat_reuses_one_gateway" {
  command = plan

  variables {
    name             = "stratovio-test"
    vpc_cidr         = "10.31.0.0/16"
    nat_gateway_mode = "single"

    subnets = {
      us-east-2a = {
        public_cidr   = "10.31.0.0/24"
        private_cidr  = "10.31.10.0/24"
        database_cidr = "10.31.20.0/24"
      }
      us-east-2b = {
        public_cidr   = "10.31.1.0/24"
        private_cidr  = "10.31.11.0/24"
        database_cidr = "10.31.21.0/24"
      }
    }
  }

  assert {
    condition     = length(output.nat_gateway_ids) == 1
    error_message = "single mode must create exactly one NAT gateway."
  }

  assert {
    condition     = length(output.private_nat_gateway_ids_by_az) == 2
    error_message = "Every private subnet must receive a default route."
  }

  assert {
    condition     = length(distinct(values(output.private_nat_gateway_ids_by_az))) == 1
    error_message = "Every private subnet must use the same NAT gateway in single mode."
  }
}

run "isolated_mode_has_no_nat_or_private_default_routes" {
  command = plan

  variables {
    name                         = "stratovio-test"
    vpc_cidr                     = "10.32.0.0/16"
    nat_gateway_mode             = "none"
    create_database_subnet_group = false
    enable_flow_logs             = true

    subnets = {
      us-east-2a = {
        public_cidr   = "10.32.0.0/24"
        private_cidr  = "10.32.10.0/24"
        database_cidr = "10.32.20.0/24"
      }
      us-east-2b = {
        public_cidr   = "10.32.1.0/24"
        private_cidr  = "10.32.11.0/24"
        database_cidr = "10.32.21.0/24"
      }
    }
  }

  assert {
    condition     = length(output.nat_gateway_ids) == 0
    error_message = "none mode must not create NAT gateways."
  }

  assert {
    condition     = length(output.private_nat_gateway_ids_by_az) == 0
    error_message = "none mode must not create private default routes."
  }

  assert {
    condition     = output.database_subnet_group_name == null
    error_message = "The database subnet group must be absent when creation is disabled."
  }

  assert {
    condition     = output.flow_log_id != null
    error_message = "Flow logs should be created when enabled."
  }
}

run "rejects_unknown_nat_mode" {
  command = plan

  variables {
    name             = "stratovio-test"
    vpc_cidr         = "10.33.0.0/16"
    nat_gateway_mode = "shared"

    subnets = {
      us-east-2a = {
        public_cidr   = "10.33.0.0/24"
        private_cidr  = "10.33.10.0/24"
        database_cidr = "10.33.20.0/24"
      }
      us-east-2b = {
        public_cidr   = "10.33.1.0/24"
        private_cidr  = "10.33.11.0/24"
        database_cidr = "10.33.21.0/24"
      }
    }
  }

  expect_failures = [var.nat_gateway_mode]
}
