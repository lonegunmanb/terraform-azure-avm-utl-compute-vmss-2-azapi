# New variables for Shadow Module
# parent_id variable for resource_group_name (Task #2)
variable "orchestrated_virtual_machine_scale_set_resource_group_id" {
  type        = string
  description = "(Required) The Resource Group ID where the Virtual Machine Scale Set should exist. Changing this forces a new resource to be created."
  nullable    = false
}

# Task #97: os_profile.custom_data - independent ephemeral variable for nested block sensitive field
variable "migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data" {
  type        = string
  nullable    = true
  ephemeral   = true
  description = "(Optional) Specifies a base-64 encoded string of custom data. The base-64 encoded string is decoded to a binary array that is saved as a file on the Virtual Machine. The maximum length of the binary array is 65535 bytes."

  validation {
    condition     = var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data == null || can(base64decode(var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data))
    error_message = "The custom_data must be a valid base64 encoded string."
  }
}

variable "migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data_version" {
  type        = number
  default     = null
  description = "(Optional) Version tracker for custom_data. Must be set when custom_data is provided."

  validation {
    condition     = var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data == null || var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data_version != null
    error_message = "When custom_data is set, custom_data_version must also be set."
  }
}

# Task #21: user_data_base64 - version variable
variable "orchestrated_virtual_machine_scale_set_user_data_base64_version" {
  type        = number
  default     = null
  description = "(Optional) Version tracker for user_data_base64. Must be set when user_data_base64 is provided."

  validation {
    condition     = var.orchestrated_virtual_machine_scale_set_user_data_base64 == null || var.orchestrated_virtual_machine_scale_set_user_data_base64_version != null
    error_message = "When user_data_base64 is set, user_data_base64_version must also be set."
  }
}
