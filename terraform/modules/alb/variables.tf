# Load Balancer
variable "name" {
  description = "Name of the load balancer"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to add to the load balancer name"
  type        = string
  default     = null
}

variable "load_balancer_type" {
  description = "Type of load balancer to create (application, network, or gateway)"
  type        = string
  default     = "application"
  validation {
    condition     = contains(["application", "network", "gateway"], var.load_balancer_type)
    error_message = "Valid values for load_balancer_type are (application, network, gateway)."
  }
}

variable "internal" {
  description = "Whether the load balancer is internal"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing of the load balancer will be enabled"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancers"
  type        = bool
  default     = true
}

variable "ip_address_type" {
  description = "The type of IP addresses used by the subnets for your load balancer (ipv4 or dualstack)"
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "Valid values for ip_address_type are (ipv4, dualstack)."
  }
}

variable "drop_invalid_header_fields" {
  description = "Indicates whether invalid header fields are dropped in application load balancers"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

# Networking
variable "vpc_id" {
  description = "ID of the VPC where to create the load balancer"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the load balancer"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the load balancer"
  type        = list(string)
  default     = []
}

# Target Group
variable "create_target_group" {
  description = "Controls if target group should be created"
  type        = bool
  default     = false
}

variable "target_group_name" {
  description = "Name of the target group"
  type        = string
  default     = null
}

variable "target_groups" {
  description = "Map of target group configurations to create"
  type        = any
  default     = {}
}

variable "target_type" {
  description = "Type of target that you must specify when registering targets with this target group"
  type        = string
  default     = "instance"
  validation {
    condition     = contains(["instance", "ip", "lambda", "alb"], var.target_type)
    error_message = "Valid values for target_type are (instance, ip, lambda, alb)."
  }
}

variable "port" {
  description = "Port on which targets receive traffic"
  type        = number
  default     = 80
}

variable "protocol" {
  description = "Protocol to use for routing traffic to the targets"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP", "TLS", "UDP", "TCP_UDP", "GENEVE"], var.protocol)
    error_message = "Valid values for protocol are (HTTP, HTTPS, TCP, TLS, UDP, TCP_UDP, GENEVE)."
  }
}

variable "protocol_version" {
  description = "Protocol version. Only applicable when protocol is HTTP or HTTPS"
  type        = string
  default     = "HTTP1"
  validation {
    condition     = contains(["HTTP1", "HTTP2", "GRPC"], var.protocol_version)
    error_message = "Valid values for protocol_version are (HTTP1, HTTP2, GRPC)."
  }
}

variable "deregistration_delay" {
  description = "Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused"
  type        = number
  default     = 300
}

variable "slow_start" {
  description = "Amount time for targets to warm up before the load balancer sends them a full share of requests"
  type        = number
  default     = 0
}

variable "stickiness" {
  description = "Target group sticky configuration"
  type        = map(string)
  default     = {}
}

variable "health_check" {
  description = "Health check configuration for the target group"
  type        = map(string)
  default     = {}
}

# Listeners
variable "create_listener" {
  description = "Controls if listener should be created"
  type        = bool
  default     = false
}

variable "listeners" {
  description = "Map of listener configurations to create"
  type        = any
  default     = {}
}

variable "listener_ssl_policy" {
  description = "Name of the SSL Policy for the listener"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}

variable "listener_certificate_arn" {
  description = "ARN of the default SSL server certificate"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
