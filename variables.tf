variable "location" {
  type        = string
  description = "(Required) Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location."
}

variable "name" {
  type        = string
  description = "(Required) The name of the this resource."
}

variable "network_interface_name" {
  type        = string
  description = "(Optional) The custom name of the network interface attached to the private endpoint. Changing this forces a new resource to be created"
}

variable "private_connection_resource_id" {
  type        = string
  description = "(Required) The ID of the Private Link Enabled Remote Resource which this Private Endpoint should be connected to."
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The resource group where the resources will be deployed."
}

variable "subnet_resource_id" {
  type        = string
  description = "(Required) Azure resource ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint. Changing this forces a new resource to be created."
}

variable "application_security_group_association_ids" {
  type        = set(string)
  default     = []
  description = "(Optional) The resource ids of application security group to associate."
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
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
}

variable "ip_configurations" {
  type = map(object({
    name               = string
    private_ip_address = string
    subresource_name   = string
    member_name        = optional(string, "default")
  }))
  default     = {}
  description = <<-EOT
  (Optional) An ip_configuration block as defined below
  map(object({
    private_ip_address = "(Required) Specifies the static IP address within the private endpoint's subnet to be used. Changing this forces a new resource to be created."
    subresource_name   = "(Required) Specifies the subresource this IP address applies to."
    member_name        = "(Optional) Specifies the member name this IP address applies to."
  }))
  EOT
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = string
  })
  default     = null
  description = "The lock level to apply. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "private_dns_zone_group_name" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Name of the Private DNS Zone Group."
}

variable "private_dns_zone_resource_ids" {
  type        = list(string)
  default     = []
  description = "(Optional) Specifies the list of Private DNS Zones to include within the private_dns_zone_group."
}

variable "private_service_connection_name" {
  type        = string
  default     = null
  description = "(Optional) Specifies the  Specifies the Name of the Private Service Connection."
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "subresource_names" {
  type        = list(string)
  default     = null
  description = "(Optional) A list of subresource names which the Private Endpoint is able to connect to. [https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource]"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to be applied to the resource"
}
