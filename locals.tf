locals {
  # Preserve the lock notes written by the AzureRM implementation so upgrades do not drift existing locks.
  lock_notes = {
    CanNotDelete = "Cannot delete the resource or its child resources."
    ReadOnly     = "Cannot delete or modify the resource or its child resources."
  }
}
