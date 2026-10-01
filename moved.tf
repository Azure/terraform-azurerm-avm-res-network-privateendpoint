moved {
  from = azurerm_private_endpoint.this
  to   = azapi_resource.this
}

moved {
  from = azurerm_private_endpoint_application_security_group_association.this
  to   = azapi_resource.application_security_group_associations
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}
