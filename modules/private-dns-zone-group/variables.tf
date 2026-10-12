variable "name" {
  type        = string
  description = "Name of the private DNS zone group."
}

variable "private_dns_zone_resource_ids" {
  type        = list(string)
  description = "Private DNS zone resource IDs to include in the private DNS zone group."
  nullable    = false
}

variable "private_endpoint_id" {
  type        = string
  description = "Resource ID of the parent private endpoint."
  nullable    = false
}

variable "resource_type" {
  type        = string
  description = "AzAPI resource type for the private DNS zone group."
  nullable    = false
}

variable "headers" {
  type        = map(string)
  default     = null
  description = "Headers to send with AzAPI resource requests."
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["ReferencedResourceNotProvisioned", "CannotDeleteResource"])
    interval_seconds     = optional(number, 10)
    max_interval_seconds = optional(number, 180)
    multiplier           = optional(number, 1.5)
    randomization_factor = optional(number, 0.5)
  })
  default     = {}
  description = "Retry configuration for AzAPI resource operations."
  nullable    = false
}

variable "timeouts" {
  type = object({
    create = optional(string, "30m")
    delete = optional(string, "30m")
    read   = optional(string, "5m")
    update = optional(string, "30m")
  })
  default     = {}
  description = "Timeout configuration for the private DNS zone group."
  nullable    = false
}
