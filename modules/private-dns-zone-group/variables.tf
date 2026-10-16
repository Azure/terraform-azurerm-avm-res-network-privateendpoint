variable "location" {
  type        = string
  description = "The Azure region for this module's resources or telemetry deployment."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Name of the private DNS zone group."
}

variable "parent_id" {
  type        = string
  description = "Fully-qualified ARM resource ID of the parent private endpoint."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Network/privateEndpoints", var.parent_id))
    error_message = "`parent_id` must be a valid private endpoint resource ID."
  }
}

variable "private_dns_zone_resource_ids" {
  type        = list(string)
  description = "Private DNS zone resource IDs to include in the private DNS zone group."
  nullable    = false

  validation {
    condition = alltrue([
      for id in var.private_dns_zone_resource_ids :
      can(provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", id))
    ])
    error_message = "Each `private_dns_zone_resource_ids` entry must be a valid private DNS zone resource ID."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "headers" {
  type        = map(string)
  default     = null
  description = "Headers to send with AzAPI resource requests."
}

variable "ignore_body_changes" {
  type = object({
    network_private_endpoints_private_dns_zone_groups = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot-notation paths ignored by the AzAPI provider. Ignored configuration is not sent to Azure until the path is removed. Changes take effect only after apply.

- `network_private_endpoints_private_dns_zone_groups` - Paths ignored on the private DNS zone group.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    network_private_endpoints_private_dns_zone_groups = optional(string, "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-07-01")
  })
  default     = {}
  description = "AzAPI resource types and API versions used by the private DNS zone group submodule."
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Retry configuration applied to the private DNS zone group AzAPI resource. Defaults to provider behavior."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Default per-operation timeouts for the private DNS zone group AzAPI resource. Defaults to provider behavior."
}
