variable "location" {
  type        = string
  description = "(Required) Azure region where the resource should be deployed.  If null, the location will be inferred from the resource group location."
  nullable    = false
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
  description = <<DESCRIPTION
  (Optional) An ip_configuration block as defined below
  map(object({
    private_ip_address = "(Required) Specifies the static IP address within the private endpoint's subnet to be used. Changing this forces a new resource to be created."
    subresource_name   = "(Required) Specifies the subresource this IP address applies to."
    member_name        = "(Optional) Specifies the member name this IP address applies to."
  }))

  Example Input:

  ```terraform
  ip_configurations ={
    "object1" = {
      name               = "<name_of_the_ip_configuration>"
      private_ip_address = "<value_of_the_static_IP >"
      subresource_name   = "<subresource_name>"
    }
  }
  ``` 
  DESCRIPTION
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
    principal_type                         = optional(string, null)
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
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.  

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Example Input:

  ```terraform
  role_assignments ={
    "object1" = {
      role_definition_id_or_name = "<role_definition_1_name>"
      principal_id               = "<object_id_of_the_principal>"
    },
    "object2" = {
      role_definition_id_or_name = "<role_definition_2_name>"
      principal_id               = "<object_id_of_the_principal>"
      description                = "<description>"
    },
  }
  ``` 
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
