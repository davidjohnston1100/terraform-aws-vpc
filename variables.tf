variable "name" {
  description = "Short, lowercase name used in resource names and Name tags."
  type        = string

  validation {
    condition = (
      length(var.name) >= 2 &&
      length(var.name) <= 32 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    )
    error_message = "name must be 2-32 lowercase characters, start with a letter, end with a letter or number, and contain only letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "subnets" {
  description = "Subnet CIDRs keyed by Availability Zone. Each AZ receives one public, one private, and one isolated database subnet."
  type = map(object({
    public_cidr   = string
    private_cidr  = string
    database_cidr = string
  }))

  validation {
    condition     = length(var.subnets) >= 2 && length(var.subnets) <= 6
    error_message = "subnets must define between two and six Availability Zones."
  }

  validation {
    condition = alltrue([
      for subnet_set in values(var.subnets) : alltrue([
        can(cidrnetmask(subnet_set.public_cidr)),
        can(cidrnetmask(subnet_set.private_cidr)),
        can(cidrnetmask(subnet_set.database_cidr))
      ])
    ])
    error_message = "Every public_cidr, private_cidr, and database_cidr must be a valid IPv4 CIDR block."
  }

  validation {
    condition = length(distinct(flatten([
      for subnet_set in values(var.subnets) : [
        subnet_set.public_cidr,
        subnet_set.private_cidr,
        subnet_set.database_cidr
      ]
    ]))) == length(var.subnets) * 3
    error_message = "Every subnet CIDR must be unique."
  }
}

variable "nat_gateway_mode" {
  description = "Private-subnet IPv4 egress strategy: none, single, or per_az."
  type        = string
  default     = "per_az"

  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be one of: none, single, per_az."
  }
}

variable "map_public_ip_on_launch" {
  description = "Whether EC2 instances launched in public subnets receive a public IPv4 address by default."
  type        = bool
  default     = false
}

variable "enable_dns_support" {
  description = "Whether the VPC supports DNS resolution."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Whether instances with public IP addresses receive public DNS hostnames."
  type        = bool
  default     = true
}

variable "enable_network_address_usage_metrics" {
  description = "Whether Network Address Usage metrics are enabled for the VPC."
  type        = bool
  default     = false
}

variable "manage_default_security_group" {
  description = "Whether to remove all ingress and egress rules from the VPC's default security group."
  type        = bool
  default     = true
}

variable "create_database_subnet_group" {
  description = "Whether to create an RDS DB subnet group from the database subnets."
  type        = bool
  default     = true
}

variable "database_subnet_group_name" {
  description = "Optional RDS DB subnet group name. Defaults to <name>-database."
  type        = string
  default     = null

  validation {
    condition = var.database_subnet_group_name == null ? true : (
      length(var.database_subnet_group_name) <= 255 &&
      var.database_subnet_group_name != "default" &&
      can(regex("^[a-z][a-z0-9.-]*$", var.database_subnet_group_name))
    )
    error_message = "database_subnet_group_name must not be default, must start with a lowercase letter, and may contain only lowercase letters, numbers, periods, and hyphens."
  }
}

variable "enable_flow_logs" {
  description = "Whether to publish VPC Flow Logs to a module-managed CloudWatch Logs group."
  type        = bool
  default     = false
}

variable "flow_log_traffic_type" {
  description = "Traffic captured by VPC Flow Logs."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log_traffic_type)
    error_message = "flow_log_traffic_type must be ACCEPT, REJECT, or ALL."
  }
}

variable "flow_log_retention_in_days" {
  description = "CloudWatch Logs retention period for VPC Flow Logs."
  type        = number
  default     = 90

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731,
      1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.flow_log_retention_in_days)
    error_message = "flow_log_retention_in_days must be a CloudWatch Logs-supported retention value."
  }
}

variable "flow_log_kms_key_id" {
  description = "Optional KMS key ARN used to encrypt the VPC Flow Logs CloudWatch log group."
  type        = string
  default     = null
}

variable "flow_log_max_aggregation_interval" {
  description = "Maximum VPC Flow Log aggregation interval in seconds."
  type        = number
  default     = 60

  validation {
    condition     = contains([60, 600], var.flow_log_max_aggregation_interval)
    error_message = "flow_log_max_aggregation_interval must be 60 or 600 seconds."
  }
}

variable "tags" {
  description = "Tags applied to all resources. Resource-specific Name tags are set by the module."
  type        = map(string)
  default     = {}
}

variable "vpc_tags" {
  description = "Additional tags applied only to the VPC."
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags applied to public subnets."
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags applied to private subnets."
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags applied to database subnets."
  type        = map(string)
  default     = {}
}
