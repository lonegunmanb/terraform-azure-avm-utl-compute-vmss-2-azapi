# New variables for Shadow Module
# parent_id variable for resource_group_name (Task #2)
variable "orchestrated_virtual_machine_scale_set_resource_group_id" {
  type        = string
  description = "(Required) The Resource Group ID where the Virtual Machine Scale Set should exist. Changing this forces a new resource to be created."
  nullable    = false
}

# Independent ephemeral variable for os_profile.custom_data (Task #97)
variable "migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data" {
  type        = string
  description = "(Optional) The Base64-Encoded Custom Data which should be used for this Virtual Machine Scale Set."
  nullable    = true
  ephemeral   = true

  validation {
    condition     = var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data == null || can(base64decode(var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data))
    error_message = "The custom_data must be a valid Base64-encoded string."
  }
}

variable "migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data_version" {
  type        = number
  description = "Version tracker for custom_data sensitive field to force updates when changed."
  default     = 1
}
