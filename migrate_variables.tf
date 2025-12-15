# New variables for Shadow Module
# parent_id variable for resource_group_name (Task #2)
variable "resource_group_id" {
  type        = string
  description = "(Required) The Resource Group ID where the Virtual Machine Scale Set should exist. Changing this forces a new resource to be created."
  nullable    = false
}

# Task #97: os_profile.custom_data - independent ephemeral variable for nested block sensitive field
variable "os_profile_custom_data" {
  type        = string
  nullable    = true
  default = null
  ephemeral   = true
  description = "(Optional) Specifies a base-64 encoded string of custom data. The base-64 encoded string is decoded to a binary array that is saved as a file on the Virtual Machine. The maximum length of the binary array is 65535 bytes."

  validation {
    condition     = var.os_profile_custom_data == null || can(base64decode(var.os_profile_custom_data))
    error_message = "The custom_data must be a valid base64 encoded string."
  }
}

variable "os_profile_custom_data_version" {
  type        = number
  default     = null
  description = "(Optional) Version tracker for custom_data. Must be set when custom_data is provided."

  validation {
    condition     = var.os_profile_custom_data == null || var.os_profile_custom_data_version != null
    error_message = "When custom_data is set, custom_data_version must also be set."
  }
}

# Task #21: user_data_base64 - version variable
variable "user_data_base64_version" {
  type        = number
  default     = null
  description = "(Optional) Version tracker for user_data_base64. Must be set when user_data_base64 is provided."

  validation {
    condition     = var.data_base64 == null || var.user_data_base64_version != null
    error_message = "When user_data_base64 is set, user_data_base64_version must also be set."
  }
}

# Task #52: extension.protected_settings - independent ephemeral variable for nested block sensitive field
variable "extension_protected_settings" {
  type = set(object({
    name               = string
    protected_settings = string
  }))
  nullable    = true
  default = null
  ephemeral   = true
  description = "(Optional) Protected settings for extensions. Each object contains extension name and its protected settings JSON."

  validation {
    condition = var.extension_protected_settings == null || alltrue([
      for ext in var.extension_protected_settings : can(jsondecode(ext.protected_settings))
    ])
    error_message = "Each protected_settings value must be a valid JSON string."
  }
}

variable "extension_protected_settings_version" {
  type        = number
  default     = null
  description = "(Optional) Version tracker for extension protected_settings. Must be set when extension protected_settings is provided."

  validation {
    condition     = var.extension_protected_settings == null || var.extension_protected_settings_version != null
    error_message = "When extension protected_settings is set, extension_protected_settings_version must also be set."
  }
}

# Task #100: os_profile.linux_configuration.admin_password - independent ephemeral variable for nested block sensitive field
variable "os_profile_linux_configuration_admin_password" {
  type        = string
  nullable    = true
  default = null
  ephemeral   = true
  description = "(Optional) The admin password to be used on the Virtual Machine Scale Set. Changing this forces a new resource to be created."

  validation {
    condition = (
      var.os_profile_linux_configuration_admin_password == null ||
      (
        length(var.os_profile_linux_configuration_admin_password) >= 6 &&
        length(var.os_profile_linux_configuration_admin_password) <= 72
      )
    )
    error_message = "admin_password must be at least 6 characters long and less than 72 characters long."
  }

  validation {
    condition = (
      var.os_profile_linux_configuration_admin_password == null ||
      length(regexall("[a-z]", var.os_profile_linux_configuration_admin_password)) +
      length(regexall("[A-Z]", var.os_profile_linux_configuration_admin_password)) +
      length(regexall("[0-9]", var.os_profile_linux_configuration_admin_password)) +
      length(regexall("[\\W_]", var.os_profile_linux_configuration_admin_password)) >= 3
    )
    error_message = "admin_password did not meet minimum password complexity requirements. A password must contain at least 3 of the 4 following conditions: a lower case character, a upper case character, a digit and/or a special character."
  }

  validation {
    condition = (
      var.os_profile_linux_configuration_admin_password == null ||
      !contains([
        "abc@123", "P@$$w0rd", "P@ssw0rd", "P@ssword123", "Pa$$word",
        "pass@word1", "Password!", "Password1", "Password22", "iloveyou!"
      ], var.os_profile_linux_configuration_admin_password)
    )
    error_message = "admin_password cannot be one of the disallowed values: 'abc@123', 'P@$$w0rd', 'P@ssw0rd', 'P@ssword123', 'Pa$$word', 'pass@word1', 'Password!', 'Password1', 'Password22', 'iloveyou!'." 
  }
}

variable "os_profile_linux_configuration_admin_password_version" {
  type        = number
  default     = null
  description = "(Optional) Version tracker for admin_password. Must be set when admin_password is provided."

  validation {
    condition     = var.os_profile_linux_configuration_admin_password == null || var.os_profile_linux_configuration_admin_password_version != null
    error_message = "When admin_password is set, admin_password_version must also be set."
  }
}

# Task #114: os_profile.windows_configuration.admin_password - independent ephemeral variable for nested block sensitive field
variable "os_profile_windows_configuration_admin_password" {
  type        = string
  default = null
  ephemeral   = true
  description = "(Required) The Password which should be used for the local-administrator on this Virtual Machine. Changing this forces a new resource to be created."

  validation {
    condition = (
      length(var.os_profile_windows_configuration_admin_password) >= 8 &&
      length(var.os_profile_windows_configuration_admin_password) <= 123
    )
    error_message = "admin_password must be at least 6 characters long and less than 72 characters long."
  }

  validation {
    condition = (
      length(regexall("[a-z]", var.os_profile_windows_configuration_admin_password)) > 0 &&
      length(regexall("[A-Z]", var.os_profile_windows_configuration_admin_password)) > 0 &&
      length(regexall("[0-9]", var.os_profile_windows_configuration_admin_password)) > 0
    ) || (
      length(regexall("[a-z]", var.os_profile_windows_configuration_admin_password)) > 0 &&
      length(regexall("[A-Z]", var.os_profile_windows_configuration_admin_password)) > 0 &&
      length(regexall("[\\W_]", var.os_profile_windows_configuration_admin_password)) > 0
    ) || (
      length(regexall("[a-z]", var.os_profile_windows_configuration_admin_password)) > 0 &&
      length(regexall("[0-9]", var.os_profile_windows_configuration_admin_password)) > 0 &&
      length(regexall("[\\W_]", var.os_profile_windows_configuration_admin_password)) > 0
    ) || (
      length(regexall("[A-Z]", var.os_profile_windows_configuration_admin_password)) > 0 &&
      length(regexall("[0-9]", var.os_profile_windows_configuration_admin_password)) > 0 &&
      length(regexall("[\\W_]", var.os_profile_windows_configuration_admin_password)) > 0
    )
    error_message = "admin_password did not meet minimum password complexity requirements. A password must contain at least 3 of the 4 following conditions: a lower case character, a upper case character, a digit and/or a special character."
  }

  validation {
    condition = !contains([
      "abc@123", "P@$$w0rd", "P@ssw0rd", "P@ssword123", "Pa$$word",
      "pass@word1", "Password!", "Password1", "Password22", "iloveyou!"
    ], var.os_profile_windows_configuration_admin_password)
    error_message = "admin_password cannot be one of the disallowed values: 'abc@123', 'P@$$w0rd', 'P@ssw0rd', 'P@ssword123', 'Pa$$word', 'pass@word1', 'Password!', 'Password1', 'Password22', 'iloveyou!'."
  }
}

variable "os_profile_windows_configuration_admin_password_version" {
  type        = number
  default     = null
  description = "(Optional) Version tracker for admin_password. Must be set when admin_password is provided."

  validation {
    condition     = var.os_profile == null || var.os_profile.windows_configuration == null || var.os_profile_windows_configuration_admin_password_version != null
    error_message = "When admin_password is set, admin_password_version must also be set."
  }
}

# Task #124: os_profile.windows_configuration.additional_unattend_content.content - independent ephemeral variable for nested block sensitive field
variable "os_profile_windows_configuration_additional_unattend_content_content" {
  type = list(object({
    index   = number
    content = string
  }))
  nullable    = true
  default = null
  ephemeral   = true
  description = "(Required for each item) The XML formatted content that is added to the unattend.xml file for the specified path and component. Changing this forces a new resource to be created."
}

variable "os_profile_windows_configuration_additional_unattend_content_content_version" {
  type        = number
  default     = null
  description = "(Optional) Version tracker for additional_unattend_content content. Must be set when additional_unattend_content is provided."

  validation {
    condition     = var.os_profile_windows_configuration_additional_unattend_content_content == null || var.os_profile_windows_configuration_additional_unattend_content_content_version != null
    error_message = "When additional_unattend_content content is set, additional_unattend_content_content_version must also be set."
  }
}
