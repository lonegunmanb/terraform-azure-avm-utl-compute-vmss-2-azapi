variable "orchestrated_virtual_machine_scale_set_location" {
  type        = string
  description = "(Required) The Azure location where the Virtual Machine Scale Set should exist. Changing this forces a new resource to be created."
  nullable    = false
}

variable "orchestrated_virtual_machine_scale_set_name" {
  type        = string
  description = "(Required) The name of the Virtual Machine Scale Set. Changing this forces a new resource to be created."
  nullable    = false

  validation {
    condition     = length(var.orchestrated_virtual_machine_scale_set_name) <= 80
    error_message = "The name can be at most 80 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.orchestrated_virtual_machine_scale_set_name))
    error_message = "The name may only contain alphanumeric characters, dots, dashes and underscores."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9]", var.orchestrated_virtual_machine_scale_set_name))
    error_message = "The name must begin with an alphanumeric character."
  }

  validation {
    condition     = can(regex("\\w$", var.orchestrated_virtual_machine_scale_set_name))
    error_message = "The name must end with an alphanumeric character or underscore."
  }

  validation {
    condition     = !can(regex("^\\d+$", var.orchestrated_virtual_machine_scale_set_name))
    error_message = "The name cannot contain only numbers."
  }
}

variable "orchestrated_virtual_machine_scale_set_platform_fault_domain_count" {
  type        = number
  description = "(Required) Specifies the number of fault domains that are used by this Virtual Machine Scale Set. Changing this forces a new resource to be created."
  nullable    = false
}

variable "orchestrated_virtual_machine_scale_set_resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group in which the Virtual Machine Scale Set should exist. Changing this forces a new resource to be created."
  nullable    = false
}

variable "orchestrated_virtual_machine_scale_set_additional_capabilities" {
  type = object({
    ultra_ssd_enabled = optional(bool, false)
  })
  default     = null
  description = <<-EOT
 - `ultra_ssd_enabled` - (Optional) Should the capacity to enable Data Disks of the `UltraSSD_LRS` storage account type be supported on this Virtual Machine Scale Set? Defaults to `false`. Changing this forces a new resource to be created.
EOT
}

variable "orchestrated_virtual_machine_scale_set_automatic_instance_repair" {
  type = object({
    action       = optional(string)
    enabled      = bool
    grace_period = optional(string)
  })
  default     = null
  description = <<-EOT
 - `action` - (Optional) The repair action that will be used for repairing unhealthy virtual machines in the scale set. Possible values include `Replace`, `Restart`, `Reimage`.
 - `enabled` - (Required) Should the automatic instance repair be enabled on this Virtual Machine Scale Set? Possible values are `true` and `false`.
 - `grace_period` - (Optional) Amount of time for which automatic repairs will be delayed. The grace period starts right after the VM is found unhealthy. Possible values are between `10` and `90` minutes. The time duration should be specified in `ISO 8601` format (e.g. `PT10M` to `PT90M`).
EOT

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_automatic_instance_repair == null ||
      var.orchestrated_virtual_machine_scale_set_automatic_instance_repair.action == null ||
      contains(["Replace", "Restart", "Reimage"], var.orchestrated_virtual_machine_scale_set_automatic_instance_repair.action)
    )
    error_message = "The action must be one of: Replace, Restart, Reimage."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_automatic_instance_repair == null ||
      var.orchestrated_virtual_machine_scale_set_automatic_instance_repair.grace_period == null ||
      can(regex("^PT([1-8]?[0-9]|90)M$", var.orchestrated_virtual_machine_scale_set_automatic_instance_repair.grace_period))
    )
    error_message = "The grace_period must be between PT10M and PT90M in ISO 8601 format."
  }
}

variable "orchestrated_virtual_machine_scale_set_boot_diagnostics" {
  type = object({
    storage_account_uri = optional(string)
  })
  default     = null
  description = <<-EOT
 - `storage_account_uri` - (Optional) The Primary/Secondary Endpoint for the Azure Storage Account which should be used to store Boot Diagnostics, including Console Output and Screenshots from the Hypervisor. By including a `boot_diagnostics` block without passing the `storage_account_uri` field will cause the API to utilize a Managed Storage Account to store the Boot Diagnostics output.
EOT
}

variable "orchestrated_virtual_machine_scale_set_capacity_reservation_group_id" {
  type        = string
  default     = null
  description = "(Optional) Specifies the ID of the Capacity Reservation Group which the Virtual Machine Scale Set should be allocated to. Changing this forces a new resource to be created."

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_capacity_reservation_group_id == null ||
      can(regex("^/subscriptions/[a-fA-F0-9]{8}-([a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}/resourceGroups/[^/]+/providers/Microsoft\\.Compute/capacityReservationGroups/[^/]+$", var.orchestrated_virtual_machine_scale_set_capacity_reservation_group_id))
    )
    error_message = "The capacity_reservation_group_id must be a valid Capacity Reservation Group ID."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_capacity_reservation_group_id == null ||
      var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id == null
    )
    error_message = "The capacity_reservation_group_id cannot be specified when proximity_placement_group_id is set (ConflictsWith)."
  }
}

  variable "orchestrated_virtual_machine_scale_set_data_disk" {
    type = list(object({
      caching                        = string
      create_option                  = optional(string, "Empty")
      disk_encryption_set_id         = optional(string)
    disk_size_gb                   = optional(number)
    lun                            = optional(number, 0)
    storage_account_type           = string
    ultra_ssd_disk_iops_read_write = optional(number)
    ultra_ssd_disk_mbps_read_write = optional(number)
    write_accelerator_enabled      = optional(bool, false)
  }))
  default     = null
  description = <<-EOT
 - `caching` - (Required) The type of Caching which should be used for this Data Disk. Possible values are None, ReadOnly and ReadWrite.
 - `create_option` - (Optional) The create option which should be used for this Data Disk. Possible values are Empty and FromImage. Defaults to `Empty`. (FromImage should only be used if the source image includes data disks).
 - `disk_encryption_set_id` - (Optional) The ID of the Disk Encryption Set which should be used to encrypt the Data Disk. Changing this forces a new resource to be created.
 - `disk_size_gb` - (Optional) The size of the Data Disk which should be created. Required if `create_option` is specified as `Empty`.
 - `lun` - (Optional) The Logical Unit Number of the Data Disk, which must be unique within the Virtual Machine. Required if `create_option` is specified as `Empty`.
 - `storage_account_type` - (Required) The Type of Storage Account which should back this Data Disk. Possible values include `Standard_LRS`, `StandardSSD_LRS`, `StandardSSD_ZRS`, `Premium_LRS`, `PremiumV2_LRS`, `Premium_ZRS` and `UltraSSD_LRS`.
 - `ultra_ssd_disk_iops_read_write` - (Optional) Specifies the Read-Write IOPS for this Data Disk. Only settable when `storage_account_type` is `PremiumV2_LRS` or `UltraSSD_LRS`.
 - `ultra_ssd_disk_mbps_read_write` - (Optional) Specifies the bandwidth in MB per second for this Data Disk. Only settable when `storage_account_type` is `PremiumV2_LRS` or `UltraSSD_LRS`.
 - `write_accelerator_enabled` - (Optional) Specifies if Write Accelerator is enabled on the Data Disk. Defaults to `false`.
EOT

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_data_disk == null ||
      alltrue([
        for disk in var.orchestrated_virtual_machine_scale_set_data_disk :
        contains(["None", "ReadOnly", "ReadWrite"], disk.caching)
      ])
    )
    error_message = "The caching must be one of: None, ReadOnly, ReadWrite."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_data_disk == null ||
      alltrue([
        for disk in var.orchestrated_virtual_machine_scale_set_data_disk :
        contains(["Premium_LRS", "PremiumV2_LRS", "Premium_ZRS", "Standard_LRS", "StandardSSD_LRS", "StandardSSD_ZRS", "UltraSSD_LRS"], disk.storage_account_type)
      ])
    )
    error_message = "The storage_account_type must be one of: Premium_LRS, PremiumV2_LRS, Premium_ZRS, Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, UltraSSD_LRS."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_data_disk == null ||
      alltrue([
        for disk in var.orchestrated_virtual_machine_scale_set_data_disk :
        disk.ultra_ssd_disk_iops_read_write == null || disk.ultra_ssd_disk_iops_read_write >= 1
      ])
    )
    error_message = "The ultra_ssd_disk_iops_read_write must be at least 1."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_data_disk == null ||
      var.orchestrated_virtual_machine_scale_set_additional_capabilities == null ||
      alltrue([
        for disk in var.orchestrated_virtual_machine_scale_set_data_disk :
        disk.ultra_ssd_disk_iops_read_write == null ||
        disk.ultra_ssd_disk_iops_read_write <= 0 ||
        coalesce(var.orchestrated_virtual_machine_scale_set_additional_capabilities.ultra_ssd_enabled, false) ||
        disk.storage_account_type == "PremiumV2_LRS"
      ])
    )
    error_message = "`ultra_ssd_disk_iops_read_write` can only be set when `storage_account_type` is set to `PremiumV2_LRS` or `UltraSSD_LRS`."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_data_disk == null ||
      alltrue([
        for disk in var.orchestrated_virtual_machine_scale_set_data_disk :
        disk.ultra_ssd_disk_mbps_read_write == null || disk.ultra_ssd_disk_mbps_read_write >= 1
      ])
    )
    error_message = "The ultra_ssd_disk_mbps_read_write must be at least 1."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_data_disk == null ||
      var.orchestrated_virtual_machine_scale_set_additional_capabilities == null ||
      alltrue([
        for disk in var.orchestrated_virtual_machine_scale_set_data_disk :
        disk.ultra_ssd_disk_mbps_read_write == null ||
        disk.ultra_ssd_disk_mbps_read_write <= 0 ||
        coalesce(var.orchestrated_virtual_machine_scale_set_additional_capabilities.ultra_ssd_enabled, false) ||
        disk.storage_account_type == "PremiumV2_LRS"
      ])
    )
    error_message = "`ultra_ssd_disk_mbps_read_write` can only be set when `storage_account_type` is set to `PremiumV2_LRS` or `UltraSSD_LRS`."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_data_disk == null ||
      alltrue([
        for disk in var.orchestrated_virtual_machine_scale_set_data_disk :
        contains(["Empty", "FromImage"], disk.create_option)
      ])
    )
    error_message = "The create_option must be one of: Empty, FromImage."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_data_disk == null ||
      alltrue([
        for disk in var.orchestrated_virtual_machine_scale_set_data_disk :
        disk.disk_size_gb == null || (disk.disk_size_gb >= 1 && disk.disk_size_gb <= 32767)
      ])
    )
    error_message = "The disk_size_gb must be between 1 and 32767."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_data_disk == null ||
      alltrue([
        for disk in var.orchestrated_virtual_machine_scale_set_data_disk :
        disk.lun == null || (disk.lun >= 0 && disk.lun <= 2000)
      ])
    )
    error_message = "The lun must be between 0 and 2000."
  }
}

variable "orchestrated_virtual_machine_scale_set_encryption_at_host_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Should disks attached to this Virtual Machine Scale Set be encrypted by enabling Encryption at Host?"
}

variable "orchestrated_virtual_machine_scale_set_eviction_policy" {
  type        = string
  default     = null
  description = "(Optional) The Policy which should be used by Spot Virtual Machines that are Evicted from the Scale Set. Possible values are `Deallocate` and `Delete`. Changing this forces a new resource to be created."

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_eviction_policy == null ||
      contains(["Deallocate", "Delete"], var.orchestrated_virtual_machine_scale_set_eviction_policy)
    )
    error_message = "The eviction_policy must be either 'Deallocate' or 'Delete'."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_eviction_policy == null ||
      var.orchestrated_virtual_machine_scale_set_priority == "Spot"
    )
    error_message = "`eviction_policy` can only be specified when `priority` is set to `Spot`."
  }
}

variable "orchestrated_virtual_machine_scale_set_extension" {
  type = set(object({
    auto_upgrade_minor_version_enabled        = optional(bool, true)
    extensions_to_provision_after_vm_creation = optional(list(string))
    failure_suppression_enabled               = optional(bool, false)
    force_extension_execution_on_change       = optional(string)
    name                                      = string
    protected_settings                        = optional(string) # TODO: delete later - migrated to independent ephemeral variable (Task #52)
    publisher                                 = string
    settings                                  = optional(string)
    type                                      = string
    type_handler_version                      = string
    protected_settings_from_key_vault = optional(object({
      secret_url      = string
      source_vault_id = string
    }))
  }))
  default     = null
  description = <<-EOT
 - `auto_upgrade_minor_version_enabled` - (Optional) Should the latest version of the Extension be used at Deployment Time, if one is available? This won't auto-update the extension on existing installation. Defaults to `true`.
 - `extensions_to_provision_after_vm_creation` - (Optional) An ordered list of Extension names which Virtual Machine Scale Set should provision after VM creation.
 - `failure_suppression_enabled` - (Optional) Should failures from the extension be suppressed? Possible values are `true` or `false`.
 - `force_extension_execution_on_change` - (Optional) A value which, when different to the previous value can be used to force-run the Extension even if the Extension Configuration hasn't changed.
 - `name` - (Required) The name for the Virtual Machine Scale Set Extension.
 - `protected_settings` - (Optional) A JSON String which specifies Sensitive Settings (such as Passwords) for the Extension.
 - `publisher` - (Required) Specifies the Publisher of the Extension.
 - `settings` - (Optional) A JSON String which specifies Settings for the Extension.
 - `type` - (Required) Specifies the Type of the Extension.
 - `type_handler_version` - (Required) Specifies the version of the extension to use, available versions can be found using the Azure CLI.

 ---
 `protected_settings_from_key_vault` block supports the following:
 - `secret_url` - (Required) The URL to the Key Vault Secret which stores the protected settings.
 - `source_vault_id` - (Required) The ID of the source Key Vault.
EOT

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_extension == null ||
      alltrue([for ext in var.orchestrated_virtual_machine_scale_set_extension : ext.name != ""])
    )
    error_message = "The extension name must not be empty."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_extension == null ||
      alltrue([for ext in var.orchestrated_virtual_machine_scale_set_extension : ext.type_handler_version != ""])
    )
    error_message = "The extension type_handler_version must not be empty."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_extension == null ||
      alltrue([for ext in var.orchestrated_virtual_machine_scale_set_extension : ext.publisher != ""])
    )
    error_message = "The extension publisher must not be empty."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_extension == null ||
      alltrue([for ext in var.orchestrated_virtual_machine_scale_set_extension : ext.type != ""])
    )
    error_message = "The extension type must not be empty."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_extension == null ||
      alltrue([
        for ext in var.orchestrated_virtual_machine_scale_set_extension :
        ext.extensions_to_provision_after_vm_creation == null ||
        alltrue([for name in ext.extensions_to_provision_after_vm_creation : name != ""])
      ])
    )
    error_message = "Each extension name in extensions_to_provision_after_vm_creation must not be empty."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_extension == null ||
      alltrue([
        for ext in var.orchestrated_virtual_machine_scale_set_extension :
        ext.settings == null || ext.settings == "" || can(jsondecode(ext.settings))
      ])
    )
    error_message = "The extension settings must be a valid JSON string."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_extension == null ||
      alltrue([
        for ext in var.orchestrated_virtual_machine_scale_set_extension :
        !(ext.protected_settings != null && ext.protected_settings != "" && ext.protected_settings_from_key_vault != null)
      ])
    )
    error_message = "protected_settings_from_key_vault cannot be used with protected_settings for the same extension."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_extension == null ||
      var.migrate_orchestrated_virtual_machine_scale_set_extension_protected_settings == null ||
      alltrue([
        for ext in var.orchestrated_virtual_machine_scale_set_extension :
        ext.protected_settings_from_key_vault == null ||
        !contains([for ps_ext in var.migrate_orchestrated_virtual_machine_scale_set_extension_protected_settings : ps_ext.name], ext.name)
      ])
    )
    error_message = "protected_settings_from_key_vault cannot be used with protected_settings (via migrate variable) for the same extension."
  }
}

variable "orchestrated_virtual_machine_scale_set_extension_operations_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Should extension operations be allowed on the Virtual Machine Scale Set? Possible values are `true` or `false`. Defaults to `true`. Changing this forces a new Virtual Machine Scale Set to be created."

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_extension_operations_enabled == false ||
      (var.orchestrated_virtual_machine_scale_set_os_profile != null &&
        var.orchestrated_virtual_machine_scale_set_os_profile.windows_configuration != null &&
      var.orchestrated_virtual_machine_scale_set_os_profile.windows_configuration.provision_vm_agent == false) == false
    )
    error_message = "`extension_operations_enabled` cannot be set to `true` when `provision_vm_agent` is set to `false` in windows_configuration."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_extension_operations_enabled == false ||
      (var.orchestrated_virtual_machine_scale_set_os_profile != null &&
        var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration != null &&
      var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.provision_vm_agent == false) == false
    )
    error_message = "`extension_operations_enabled` cannot be set to `true` when `provision_vm_agent` is set to `false` in linux_configuration."
  }
}

variable "orchestrated_virtual_machine_scale_set_extensions_time_budget" {
  type        = string
  default     = "PT1H30M"
  description = "(Optional) Specifies the time alloted for all extensions to start. The time duration should be between 15 minutes and 120 minutes (inclusive) and should be specified in ISO 8601 format. Defaults to `PT1H30M`."

  validation {
    condition = var.orchestrated_virtual_machine_scale_set_extensions_time_budget == null || can(regex("^PT([0-9]+H)?([0-9]+M)?$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)) && (
      can(regex("^PT([0-9]+)H([0-9]+)M$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)) ? (
        tonumber(regex("^PT([0-9]+)H([0-9]+)M$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)[0]) * 60 + tonumber(regex("^PT([0-9]+)H([0-9]+)M$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)[1]) >= 15 &&
        tonumber(regex("^PT([0-9]+)H([0-9]+)M$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)[0]) * 60 + tonumber(regex("^PT([0-9]+)H([0-9]+)M$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)[1]) <= 120
        ) : can(regex("^PT([0-9]+)H$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)) ? (
        tonumber(regex("^PT([0-9]+)H$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)[0]) * 60 >= 15 &&
        tonumber(regex("^PT([0-9]+)H$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)[0]) * 60 <= 120
        ) : can(regex("^PT([0-9]+)M$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)) ? (
        tonumber(regex("^PT([0-9]+)M$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)[0]) >= 15 &&
        tonumber(regex("^PT([0-9]+)M$", var.orchestrated_virtual_machine_scale_set_extensions_time_budget)[0]) <= 120
      ) : false
    )
    error_message = "The extensions_time_budget must be between PT15M and PT2H (15 minutes to 120 minutes) in ISO 8601 format."
  }
}

variable "orchestrated_virtual_machine_scale_set_identity" {
  type = object({
    identity_ids = set(string)
    type         = string
  })
  default     = null
  description = <<-EOT
 - `identity_ids` - (Required) Specifies a list of User Managed Identity IDs to be assigned to this Windows Virtual Machine Scale Set.
 - `type` - (Required) The type of Managed Identity that should be configured on this Windows Virtual Machine Scale Set. Only possible value is `UserAssigned`.
EOT

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_identity == null ||
      var.orchestrated_virtual_machine_scale_set_identity.type == "UserAssigned"
    )
    error_message = "The type must be 'UserAssigned'."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_identity == null ||
      (length(var.orchestrated_virtual_machine_scale_set_identity.identity_ids) > 0 &&
        alltrue([for id in var.orchestrated_virtual_machine_scale_set_identity.identity_ids : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.ManagedIdentity/userAssignedIdentities/[^/]+$", id))]))
    )
    error_message = "All identity_ids must be valid User Assigned Identity resource IDs in the format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{identityName}."
  }
}

variable "orchestrated_virtual_machine_scale_set_instances" {
  type        = number
  default     = null
  description = "(Optional) The number of Virtual Machines in the Virtual Machine Scale Set."

  validation {
    condition     = var.orchestrated_virtual_machine_scale_set_instances == null || (var.orchestrated_virtual_machine_scale_set_instances >= 0 && var.orchestrated_virtual_machine_scale_set_instances <= 1000)
    error_message = "The instances must be between 0 and 1000."
  }
}

variable "orchestrated_virtual_machine_scale_set_license_type" {
  type        = string
  default     = null
  description = "(Optional) Specifies the type of on-premise license (also known as Azure Hybrid Use Benefit) which should be used for this Virtual Machine Scale Set. Possible values are `None`, `Windows_Client` and `Windows_Server`."

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_license_type == null ||
      contains(["None", "Windows_Client", "Windows_Server"], var.orchestrated_virtual_machine_scale_set_license_type)
    )
    error_message = "The license_type must be one of 'None', 'Windows_Client', or 'Windows_Server'."
  }
}

variable "orchestrated_virtual_machine_scale_set_max_bid_price" {
  type        = number
  default     = -1
  description = "(Optional) The maximum price you're willing to pay for each Virtual Machine in this Scale Set, in US Dollars; which must be greater than the current spot price. If this bid price falls below the current spot price the Virtual Machines in the Scale Set will be evicted using the eviction_policy. Defaults to `-1`, which means that each Virtual Machine in the Scale Set should not be evicted for price reasons."

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_max_bid_price == -1 ||
      var.orchestrated_virtual_machine_scale_set_max_bid_price >= 0.00001
    )
    error_message = "The max_bid_price must be either -1 (to use current VM price) or greater than or equal to 0.00001."
  }
}

variable "orchestrated_virtual_machine_scale_set_network_api_version" {
  type        = string
  default     = null
  description = "(Optional) Specifies the Microsoft.Network API version used when creating networking resources in the Network Interface Configurations for Virtual Machine Scale Set. Possible values are `2020-11-01` and `2022-11-01`. Defaults to `2020-11-01`."

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_api_version == null ||
      contains(["2020-11-01", "2022-11-01"], var.orchestrated_virtual_machine_scale_set_network_api_version)
    )
    error_message = "The network_api_version must be either '2020-11-01' or '2022-11-01'."
  }
}

variable "orchestrated_virtual_machine_scale_set_network_interface" {
  type = list(object({
    auxiliary_mode                = optional(string)
    auxiliary_sku                 = optional(string)
    dns_servers                   = optional(list(string))
    enable_accelerated_networking = optional(bool, false)
    enable_ip_forwarding          = optional(bool, false)
    name                          = string
    network_security_group_id     = optional(string)
    primary                       = optional(bool, false)
    ip_configuration = list(object({
      application_gateway_backend_address_pool_ids = optional(set(string))
      application_security_group_ids               = optional(set(string))
      load_balancer_backend_address_pool_ids       = optional(set(string))
      name                                         = string
      primary                                      = optional(bool, false)
      subnet_id                                    = optional(string)
      version                                      = optional(string, "IPv4")
      public_ip_address = optional(list(object({
        domain_name_label       = optional(string)
        idle_timeout_in_minutes = optional(number)
        name                    = string
        public_ip_prefix_id     = optional(string)
        sku_name                = optional(string)
        version                 = optional(string, "IPv4")
        ip_tag = optional(list(object({
          tag  = string
          type = string
        })))
      })))
    }))
  }))
  default     = null
  description = <<-EOT
 - `auxiliary_mode` - (Optional) Specifies the auxiliary mode used to enable network high-performance feature on Network Virtual Appliances (NVAs). This feature offers competitive performance in Connections Per Second (CPS) optimization, along with improvements to handling large amounts of simultaneous connections. Possible values are `AcceleratedConnections` and `Floating`.
 - `auxiliary_sku` - (Optional) Specifies the SKU used for the network high-performance feature on Network Virtual Appliances (NVAs). Possible values are `A1`, `A2`, `A4` and `A8`.
 - `dns_servers` - (Optional) A list of IP Addresses of DNS Servers which should be assigned to the Network Interface.
 - `enable_accelerated_networking` - (Optional) Does this Network Interface support Accelerated Networking? Possible values are `true` and `false`. Defaults to `false`.
 - `enable_ip_forwarding` - (Optional) Does this Network Interface support IP Forwarding? Possible values are `true` and `false`. Defaults to `false`.
 - `name` - (Required) The Name which should be used for this Network Interface. Changing this forces a new resource to be created.
 - `network_security_group_id` - (Optional) The ID of a Network Security Group which should be assigned to this Network Interface.
 - `primary` - (Optional) Is this the Primary IP Configuration? Possible values are `true` and `false`. Defaults to `false`.

 ---
 `ip_configuration` block supports the following:
 - `application_gateway_backend_address_pool_ids` - (Optional) A list of Backend Address Pools IDs from a Application Gateway which this Virtual Machine Scale Set should be connected to.
 - `application_security_group_ids` - (Optional) A list of Application Security Group IDs which this Virtual Machine Scale Set should be connected to.
 - `load_balancer_backend_address_pool_ids` - (Optional) A list of Backend Address Pools IDs from a Load Balancer which this Virtual Machine Scale Set should be connected to.
 - `name` - (Required) The Name which should be used for this IP Configuration.
 - `primary` - (Optional) Is this the Primary IP Configuration for this Network Interface? Possible values are `true` and `false`. Defaults to `false`.
 - `subnet_id` - (Optional) The ID of the Subnet which this IP Configuration should be connected to.
 - `version` - (Optional) The Internet Protocol Version which should be used for this IP Configuration. Possible values are `IPv4` and `IPv6`. Defaults to `IPv4`.

 ---
 `public_ip_address` block supports the following:
 - `domain_name_label` - (Optional) The Prefix which should be used for the Domain Name Label for each Virtual Machine Instance. Azure concatenates the Domain Name Label and Virtual Machine Index to create a unique Domain Name Label for each Virtual Machine. Valid values must be between `1` and `26` characters long, start with a lower case letter, end with a lower case letter or number and contains only `a-z`, `0-9` and `hyphens`.
 - `idle_timeout_in_minutes` - (Optional) The Idle Timeout in Minutes for the Public IP Address. Possible values are in the range `4` to `32`.
 - `name` - (Required) The Name of the Public IP Address Configuration.
 - `public_ip_prefix_id` - (Optional) The ID of the Public IP Address Prefix from where Public IP Addresses should be allocated. Changing this forces a new resource to be created.
 - `sku_name` - (Optional) Specifies what Public IP Address SKU the Public IP Address should be provisioned as. Possible vaules include `Basic_Regional`, `Basic_Global`, `Standard_Regional` or `Standard_Global`. For more information about Public IP Address SKU's and their capabilities, please see the [product documentation](https://docs.microsoft.com/azure/virtual-network/ip-services/public-ip-addresses#sku). Changing this forces a new resource to be created.
 - `version` - (Optional) The Internet Protocol Version which should be used for this public IP address. Possible values are `IPv4` and `IPv6`. Defaults to `IPv4`. Changing this forces a new resource to be created.

 ---
 `ip_tag` block supports the following:
 - `tag` - (Required) The IP Tag associated with the Public IP, such as `SQL` or `Storage`. Changing this forces a new resource to be created.
 - `type` - (Required) The Type of IP Tag, such as `FirstPartyUsage`. Changing this forces a new resource to be created.
EOT

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([for nic in var.orchestrated_virtual_machine_scale_set_network_interface : nic.name != ""])
    )
    error_message = "The network_interface name must not be empty."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface :
        nic.auxiliary_mode == null || contains(["AcceleratedConnections", "Floating"], nic.auxiliary_mode)
      ])
    )
    error_message = "The auxiliary_mode must be either 'AcceleratedConnections' or 'Floating'."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface :
        (nic.auxiliary_mode != null && nic.auxiliary_sku != null) || (nic.auxiliary_mode == null && nic.auxiliary_sku == null)
      ])
    )
    error_message = "When auxiliary_mode is set, auxiliary_sku must also be set, and vice versa."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface :
        nic.auxiliary_mode == null || (var.orchestrated_virtual_machine_scale_set_network_api_version != null && var.orchestrated_virtual_machine_scale_set_network_api_version != "2020-11-01")
      ])
    )
    error_message = "auxiliary_mode and auxiliary_sku can be set only when network_api_version is later than '2020-11-01'."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface :
        nic.auxiliary_sku == null || contains(["A1", "A2", "A4", "A8"], nic.auxiliary_sku)
      ])
    )
    error_message = "The auxiliary_sku must be one of: 'A1', 'A2', 'A4', 'A8'."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface :
        nic.dns_servers == null || alltrue([for dns in nic.dns_servers : dns != ""])
      ])
    )
    error_message = "Each DNS server in dns_servers must not be empty."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : alltrue([
          for ip_config in nic.ip_configuration :
          ip_config.name != null && ip_config.name != ""
        ])
      ])
    )
    error_message = "Each IP configuration name must not be empty."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : alltrue([
          for ip_config in nic.ip_configuration :
          ip_config.application_security_group_ids == null || length(ip_config.application_security_group_ids) <= 20
        ])
      ])
    )
    error_message = "Each ip_configuration's application_security_group_ids can have at most 20 items."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : alltrue([
          for ip_config in nic.ip_configuration :
          ip_config.version == null || contains(["IPv4", "IPv6"], ip_config.version)
        ])
      ])
    )
    error_message = "The version must be either 'IPv4' or 'IPv6'."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : alltrue([
          for ip_config in nic.ip_configuration :
          !(ip_config.primary == true && ip_config.version == "IPv6")
        ])
      ])
    )
    error_message = "An IPv6 Primary IP Configuration is unsupported - instead add a IPv4 IP Configuration as the Primary and make the IPv6 IP Configuration the secondary."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : alltrue([
          for ip_config in nic.ip_configuration :
          ip_config.public_ip_address == null || alltrue([
            for pub_ip in ip_config.public_ip_address :
            pub_ip.name != null && pub_ip.name != ""
          ])
        ])
      ])
    )
    error_message = "The public_ip_address name must not be empty."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : alltrue([
          for ip_config in nic.ip_configuration :
          ip_config.public_ip_address == null || alltrue([
            for pub_ip in ip_config.public_ip_address :
            pub_ip.domain_name_label == null || (
              length(pub_ip.domain_name_label) >= 1 &&
              length(pub_ip.domain_name_label) <= 26 &&
              can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", pub_ip.domain_name_label))
            )
          ])
        ])
      ])
    )
    error_message = "The domain_name_label must be between 1 and 26 characters long, start with a lower case letter, end with a lower case letter or number, and contain only a-z, 0-9, and hyphens."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : alltrue([
          for ip_config in nic.ip_configuration :
          ip_config.public_ip_address == null || alltrue([
            for pub_ip in ip_config.public_ip_address :
            pub_ip.idle_timeout_in_minutes == null || (pub_ip.idle_timeout_in_minutes >= 4 && pub_ip.idle_timeout_in_minutes <= 32)
          ])
        ])
      ])
    )
    error_message = "The idle_timeout_in_minutes must be between 4 and 32."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : alltrue([
          for ip_config in nic.ip_configuration :
          ip_config.public_ip_address == null || alltrue([
            for pub_ip in ip_config.public_ip_address :
            pub_ip.sku_name == null || contains(["Basic_Regional", "Standard_Regional", "Basic_Global", "Standard_Global"], pub_ip.sku_name)
          ])
        ])
      ])
    )
    error_message = "The sku_name must be one of: 'Basic_Regional', 'Standard_Regional', 'Basic_Global', 'Standard_Global'."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : alltrue([
          for ip_config in nic.ip_configuration :
          ip_config.public_ip_address == null || alltrue([
            for pub_ip in ip_config.public_ip_address :
            pub_ip.ip_tag == null || alltrue([
              for ip_tag in pub_ip.ip_tag :
              ip_tag.tag != null && ip_tag.tag != ""
            ])
          ])
        ])
      ])
    )
    error_message = "Each IP tag's 'tag' field must not be empty."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_network_interface == null ||
      alltrue([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : alltrue([
          for ip_config in nic.ip_configuration :
          ip_config.public_ip_address == null || alltrue([
            for pub_ip in ip_config.public_ip_address :
            pub_ip.ip_tag == null || alltrue([
              for ip_tag in pub_ip.ip_tag :
              ip_tag.type != null && ip_tag.type != ""
            ])
          ])
        ])
      ])
    )
    error_message = "Each IP tag's 'type' field must not be empty."
  }
}

variable "orchestrated_virtual_machine_scale_set_os_disk" {
  type = object({
    caching                   = string
    disk_encryption_set_id    = optional(string)
    disk_size_gb              = optional(number)
    storage_account_type      = string
    write_accelerator_enabled = optional(bool, false)
    diff_disk_settings = optional(object({
      option    = string
      placement = optional(string, "CacheDisk")
    }))
  })
  default     = null
  description = <<-EOT
 - `caching` - (Required) The Type of Caching which should be used for the Internal OS Disk. Possible values are `None`, `ReadOnly` and `ReadWrite`.
 - `disk_encryption_set_id` - (Optional) The ID of the Disk Encryption Set which should be used to encrypt this OS Disk. Changing this forces a new resource to be created.
 - `disk_size_gb` - (Optional) The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image this Virtual Machine Scale Set is sourced from.
 - `storage_account_type` - (Required) The Type of Storage Account which should back this the Internal OS Disk. Possible values include `Standard_LRS`, `StandardSSD_LRS`, `StandardSSD_ZRS`, `Premium_LRS` and `Premium_ZRS`. Changing this forces a new resource to be created.
 - `write_accelerator_enabled` - (Optional) Specifies if Write Accelerator is enabled on the OS Disk. Defaults to `false`.

 `diff_disk_settings` block supports the following:
 - `option` - (Required) Specifies the Ephemeral Disk Settings for the OS Disk. At this time the only possible value is `Local`. Changing this forces a new resource to be created.
 - `placement` - (Optional) Specifies where to store the Ephemeral Disk. Possible values are `CacheDisk` and `ResourceDisk`. Defaults to `CacheDisk`. Changing this forces a new resource to be created.
EOT

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_os_disk == null ||
      contains(["None", "ReadOnly", "ReadWrite"], var.orchestrated_virtual_machine_scale_set_os_disk.caching)
    )
    error_message = "The caching type must be one of: None, ReadOnly, ReadWrite."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_os_disk == null ||
      contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "Premium_ZRS", "StandardSSD_ZRS"], var.orchestrated_virtual_machine_scale_set_os_disk.storage_account_type)
    )
    error_message = "The storage_account_type must be one of: Standard_LRS, Premium_LRS, StandardSSD_LRS, Premium_ZRS, StandardSSD_ZRS. Note: UltraSSD_LRS and PremiumV2_LRS are not supported for OS Disks."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_os_disk == null ||
      var.orchestrated_virtual_machine_scale_set_os_disk.disk_size_gb == null ||
      (var.orchestrated_virtual_machine_scale_set_os_disk.disk_size_gb >= 0 && var.orchestrated_virtual_machine_scale_set_os_disk.disk_size_gb <= 4095)
    )
    error_message = "The disk_size_gb must be between 0 and 4095."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_os_disk == null ||
      var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings == null ||
      var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings.option == "Local"
    )
    error_message = "The diff_disk_settings.option must be 'Local'."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_os_disk == null ||
      var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings == null ||
      var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings.placement == null ||
      contains(["CacheDisk", "ResourceDisk"], var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings.placement)
    )
    error_message = "The diff_disk_settings.placement must be either 'CacheDisk' or 'ResourceDisk'."
  }
}

variable "orchestrated_virtual_machine_scale_set_os_profile" {
  type = object({
    custom_data = optional(string) # TODO: delete later - migrated to independent ephemeral variable (Task #97)
    linux_configuration = optional(object({
      admin_password                  = optional(string) # TODO: delete later - migrated to independent ephemeral variable (Task #100)
      admin_username                  = string
      computer_name_prefix            = optional(string) # Computed - defaults to VMSS name if not specified
      disable_password_authentication = optional(bool, true)
      patch_assessment_mode           = optional(string, "ImageDefault")
      patch_mode                      = optional(string, "ImageDefault")
      provision_vm_agent              = optional(bool, true)
      admin_ssh_key = optional(set(object({
        public_key = string
        username   = string
      })))
      secret = optional(list(object({
        key_vault_id = string
        certificate = set(object({
          url = string
        }))
      })))
    }))
    windows_configuration = optional(object({
      admin_password           = string
      admin_username           = string
      computer_name_prefix     = optional(string)
      enable_automatic_updates = optional(bool, true)
      hotpatching_enabled      = optional(bool)
      patch_assessment_mode    = optional(string)
      patch_mode               = optional(string)
      provision_vm_agent       = optional(bool)
      timezone                 = optional(string)
      additional_unattend_content = optional(list(object({
        content = string
        setting = string
      })))
      secret = optional(list(object({
        key_vault_id = string
        certificate = set(object({
          store = string
          url   = string
        }))
      })))
      winrm_listener = optional(set(object({
        certificate_url = optional(string)
        protocol        = string
      })))
    }))
  })
  default     = null

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_os_profile == null ||
      var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration == null ||
      !var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.disable_password_authentication ||
      var.migrate_orchestrated_virtual_machine_scale_set_os_profile_linux_configuration_admin_password == null
    )
    error_message = "When disable_password_authentication is true (the default), admin_password must not be specified."
  }

  validation {
    condition = var.orchestrated_virtual_machine_scale_set_os_profile == null || var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration == null || var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.patch_assessment_mode == null || contains(["AutomaticByPlatform", "ImageDefault"], var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.patch_assessment_mode)
    error_message = "The patch_assessment_mode must be either 'AutomaticByPlatform' or 'ImageDefault'."
  }

  validation {
    condition = var.orchestrated_virtual_machine_scale_set_os_profile == null || var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration == null || var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.patch_assessment_mode != "AutomaticByPlatform" || var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.provision_vm_agent == true
    error_message = "When patch_assessment_mode is set to 'AutomaticByPlatform', provision_vm_agent must be set to true."
  }

  validation {
    condition = var.orchestrated_virtual_machine_scale_set_os_profile == null || var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration == null || var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.patch_mode == null || contains(["ImageDefault", "AutomaticByPlatform"], var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.patch_mode)
    error_message = "The patch_mode must be either 'ImageDefault' or 'AutomaticByPlatform'."
  }

  validation {
    condition = var.orchestrated_virtual_machine_scale_set_os_profile == null || var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration == null || var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.patch_mode != "AutomaticByPlatform" || var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.provision_vm_agent == true
    error_message = "When patch_mode is set to 'AutomaticByPlatform', provision_vm_agent must be set to true."
  }

  description = <<-EOT
 - `custom_data` - (Optional) The Base64-Encoded Custom Data which should be used for this Virtual Machine Scale Set.

 ---
 `linux_configuration` block supports the following:
 - `admin_password` - (Optional) The Password which should be used for the local-administrator on this Virtual Machine. Changing this forces a new resource to be created.
 - `admin_username` - (Required) The username of the local administrator on each Virtual Machine Scale Set instance. Changing this forces a new resource to be created.
 - `computer_name_prefix` - (Optional) The prefix which should be used for the name of the Virtual Machines in this Scale Set. If unspecified this defaults to the value for the name field. If the value of the name field is not a valid `computer_name_prefix`, then you must specify `computer_name_prefix`. Changing this forces a new resource to be created.
 - `disable_password_authentication` - (Optional) When an `admin_password` is specified `disable_password_authentication` must be set to `false`. Defaults to `true`.
 - `patch_assessment_mode` - (Optional) Specifies the mode of VM Guest Patching for the virtual machines that are associated to the Virtual Machine Scale Set. Possible values are `AutomaticByPlatform` or `ImageDefault`. Defaults to `ImageDefault`.
 - `patch_mode` - (Optional) Specifies the mode of in-guest patching of this Windows Virtual Machine. Possible values are `ImageDefault` or `AutomaticByPlatform`. Defaults to `ImageDefault`. For more information on patch modes please see the [product documentation](https://docs.microsoft.com/azure/virtual-machines/automatic-vm-guest-patching#patch-orchestration-modes).
 - `provision_vm_agent` - (Optional) Should the Azure VM Agent be provisioned on each Virtual Machine in the Scale Set? Defaults to `true`. Changing this value forces a new resource to be created.

 ---
 `admin_ssh_key` block supports the following:
 - `public_key` - (Required) The Public Key which should be used for authentication, which needs to be in `ssh-rsa` format with at least 2048-bit or in `ssh-ed25519` format.
 - `username` - (Required) The Username for which this Public SSH Key should be configured.

 ---
 `secret` block supports the following:
 - `key_vault_id` - (Required) The ID of the Key Vault from which all Secrets should be sourced.

 ---
 `certificate` block supports the following:
 - `url` - (Required) The Secret URL of a Key Vault Certificate.

 ---
 `windows_configuration` block supports the following:
 - `admin_password` - (Required) The Password which should be used for the local-administrator on this Virtual Machine. Changing this forces a new resource to be created.
 - `admin_username` - (Required) The username of the local administrator on each Virtual Machine Scale Set instance. Changing this forces a new resource to be created.
 - `computer_name_prefix` - (Optional) The prefix which should be used for the name of the Virtual Machines in this Scale Set. If unspecified this defaults to the value for the `name` field. If the value of the `name` field is not a valid `computer_name_prefix`, then you must specify `computer_name_prefix`. Changing this forces a new resource to be created.
 - `enable_automatic_updates` - (Optional) Are automatic updates enabled for this Virtual Machine? Defaults to `true`.
 - `hotpatching_enabled` - (Optional) Should the VM be patched without requiring a reboot? Possible values are `true` or `false`. Defaults to `false`. For more information about hot patching please see the [product documentation](https://docs.microsoft.com/azure/automanage/automanage-hotpatch).
 - `patch_assessment_mode` - (Optional) Specifies the mode of VM Guest Patching for the virtual machines that are associated to the Virtual Machine Scale Set. Possible values are `AutomaticByPlatform` or `ImageDefault`. Defaults to `ImageDefault`.
 - `patch_mode` - (Optional) Specifies the mode of in-guest patching of this Windows Virtual Machine. Possible values are `Manual`, `AutomaticByOS` and `AutomaticByPlatform`. Defaults to `AutomaticByOS`. For more information on patch modes please see the [product documentation](https://docs.microsoft.com/azure/virtual-machines/automatic-vm-guest-patching#patch-orchestration-modes).
 - `provision_vm_agent` - (Optional) Should the Azure VM Agent be provisioned on each Virtual Machine in the Scale Set? Defaults to `true`. Changing this value forces a new resource to be created.
 - `timezone` - (Optional) Specifies the time zone of the virtual machine, the possible values are defined [here](https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/).

 ---
 `additional_unattend_content` block supports the following:
 - `content` - (Required) The XML formatted content that is added to the unattend.xml file for the specified path and component. Changing this forces a new resource to be created.
 - `setting` - (Required) The name of the setting to which the content applies. Possible values are `AutoLogon` and `FirstLogonCommands`. Changing this forces a new resource to be created.

 ---
 `secret` block supports the following:
 - `key_vault_id` - (Required) The ID of the Key Vault from which all Secrets should be sourced.

 ---
 `certificate` block supports the following:
 - `store` - (Required) The certificate store on the Virtual Machine where the certificate should be added.
 - `url` - (Required) The Secret URL of a Key Vault Certificate.

 ---
 `winrm_listener` block supports the following:
 - `certificate_url` - (Optional) The Secret URL of a Key Vault Certificate, which must be specified when protocol is set to `Https`. Changing this forces a new resource to be created.
 - `protocol` - (Required) Specifies the protocol of listener. Possible values are `Http` or `Https`. Changing this forces a new resource to be created.
EOT

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_os_profile == null ||
      var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration == null ||
      (
        length(var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.admin_username) >= 1 &&
        length(var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.admin_username) <= 64
      )
    )
    error_message = "linux_configuration.admin_username must be between 1 and 64 characters in length."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_os_profile == null ||
      var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration == null ||
      !contains([
        " ", "abrt", "adm", "admin", "audio", "backup", "bin", "cdrom", "cgred", "console", "crontab", "daemon", "dbus", "dialout", "dip",
        "disk", "fax", "floppy", "ftp", "fuse", "games", "gnats", "gopher", "haldaemon", "halt", "irc", "kmem", "landscape", "libuuid", "list",
        "lock", "lp", "mail", "maildrop", "man", "mem", "messagebus", "mlocate", "modem", "netdev", "news", "nfsnobody", "nobody", "nogroup",
        "ntp", "operator", "oprofile", "plugdev", "polkituser", "postdrop", "postfix", "proxy", "public", "qpidd", "root", "rpc", "rpcuser",
        "sasl", "saslauth", "shadow", "shutdown", "slocate", "src", "ssh", "sshd", "staff", "stapdev", "stapusr", "sudo", "sync", "sys", "syslog",
        "tape", "tcpdump", "test", "trusted", "tty", "users", "utempter", "utmp", "uucp", "uuidd", "vcsa", "video", "voice", "wheel", "whoopsie",
        "www", "www-data", "wwwrun", "xok"
      ], lower(var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.admin_username))
    )
    error_message = "linux_configuration.admin_username cannot be one of the following reserved names (case-insensitive): ' ', 'abrt', 'adm', 'admin', 'audio', 'backup', 'bin', 'cdrom', 'cgred', 'console', 'crontab', 'daemon', 'dbus', 'dialout', 'dip', 'disk', 'fax', 'floppy', 'ftp', 'fuse', 'games', 'gnats', 'gopher', 'haldaemon', 'halt', 'irc', 'kmem', 'landscape', 'libuuid', 'list', 'lock', 'lp', 'mail', 'maildrop', 'man', 'mem', 'messagebus', 'mlocate', 'modem', 'netdev', 'news', 'nfsnobody', 'nobody', 'nogroup', 'ntp', 'operator', 'oprofile', 'plugdev', 'polkituser', 'postdrop', 'postfix', 'proxy', 'public', 'qpidd', 'root', 'rpc', 'rpcuser', 'sasl', 'saslauth', 'shadow', 'shutdown', 'slocate', 'src', 'ssh', 'sshd', 'staff', 'stapdev', 'stapusr', 'sudo', 'sync', 'sys', 'syslog', 'tape', 'tcpdump', 'test', 'trusted', 'tty', 'users', 'utempter', 'utmp', 'uucp', 'uuidd', 'vcsa', 'video', 'voice', 'wheel', 'whoopsie', 'www', 'www-data', 'wwwrun', 'xok'."
  }

  validation {
    condition = (
      var.orchestrated_virtual_machine_scale_set_os_profile == null ||
      var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration == null ||
      var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.computer_name_prefix == null ||
      (
        length(var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.computer_name_prefix) <= 58 &&
        !can(regex("^_", var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.computer_name_prefix)) &&
        !can(regex("\\.$", var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.computer_name_prefix)) &&
        !can(regex("[\\\\\"\\[\\]:|<>+=;,?*@&~!#$%^()_{}']", var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.computer_name_prefix))
      )
    )
    error_message = "linux_configuration.computer_name_prefix must be at most 58 characters, cannot begin with an underscore, cannot end with a period, and cannot contain the special characters: \\\"[]:|<>+=;,?*@&~!#$%^()_{}'"
  }
}

variable "orchestrated_virtual_machine_scale_set_plan" {
  type = object({
    name      = string
    product   = string
    publisher = string
  })
  default     = null
  description = <<-EOT
 - `name` - (Required) Specifies the name of the image from the marketplace. Changing this forces a new resource to be created.
 - `product` - (Required) Specifies the product of the image from the marketplace. Changing this forces a new resource to be created.
 - `publisher` - (Required) Specifies the publisher of the image. Changing this forces a new resource to be created.
EOT
}

variable "orchestrated_virtual_machine_scale_set_priority" {
  type        = string
  default     = "Regular"
  description = "(Optional) The Priority of this Virtual Machine Scale Set. Possible values are `Regular` and `Spot`. Defaults to `Regular`. Changing this value forces a new resource."

  validation {
    condition = contains([
      "Regular",
      "Spot"
    ], var.orchestrated_virtual_machine_scale_set_priority)
    error_message = "The priority must be either 'Regular' or 'Spot'."
  }
}

variable "orchestrated_virtual_machine_scale_set_proximity_placement_group_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the Proximity Placement Group which the Virtual Machine should be assigned to. Changing this forces a new resource to be created."

  validation {
    condition = var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id == null || can(regex("^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourceGroups/.+/providers/Microsoft.Compute/proximityPlacementGroups/.+$", var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id))
    error_message = "The proximity_placement_group_id must be a valid Proximity Placement Group Resource ID."
  }

  validation {
    condition = var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id == null || var.orchestrated_virtual_machine_scale_set_capacity_reservation_group_id == null
    error_message = "The proximity_placement_group_id cannot be specified when capacity_reservation_group_id is set (ConflictsWith)."
  }
}

variable "orchestrated_virtual_machine_scale_set_priority_mix" {
  type = object({
    base_regular_count            = optional(number)
    regular_percentage_above_base = optional(number)
  })
  default     = null
  description = <<-EOT
 - `base_regular_count` - (Optional) Specifies the base number of VMs of `Regular` priority that will be created before any VMs of priority `Spot` are created. Possible values are integers between `0` and `1000`. Defaults to `0`.
 - `regular_percentage_above_base` - (Optional) Specifies the desired percentage of VM instances that are of `Regular` priority after the base count has been reached. Possible values are integers between `0` and `100`. Defaults to `0`.
EOT
}

variable "orchestrated_virtual_machine_scale_set_rolling_upgrade_policy" {
  type = object({
    cross_zone_upgrades_enabled             = optional(bool)
    max_batch_instance_percent              = number
    max_unhealthy_instance_percent          = number
    max_unhealthy_upgraded_instance_percent = number
    maximum_surge_instances_enabled         = optional(bool)
    pause_time_between_batches              = string
    prioritize_unhealthy_instances_enabled  = optional(bool)
  })
  default     = null
  description = <<-EOT
 - `cross_zone_upgrades_enabled` - (Optional) Should the Virtual Machine Scale Set ignore the Azure Zone boundaries when constructing upgrade batches? Possible values are `true` or `false`.
 - `max_batch_instance_percent` - (Required) The maximum percent of total virtual machine instances that will be upgraded simultaneously by the rolling upgrade in one batch. As this is a maximum, unhealthy instances in previous or future batches can cause the percentage of instances in a batch to decrease to ensure higher reliability.
 - `max_unhealthy_instance_percent` - (Required) The maximum percentage of the total virtual machine instances in the scale set that can be simultaneously unhealthy, either as a result of being upgraded, or by being found in an unhealthy state by the virtual machine health checks before the rolling upgrade aborts. This constraint will be checked prior to starting any batch.
 - `max_unhealthy_upgraded_instance_percent` - (Required) The maximum percentage of upgraded virtual machine instances that can be found to be in an unhealthy state. This check will happen after each batch is upgraded. If this percentage is ever exceeded, the rolling update aborts.
 - `maximum_surge_instances_enabled` - (Optional) Create new virtual machines to upgrade the scale set, rather than updating the existing virtual machines. Existing virtual machines will be deleted once the new virtual machines are created for each batch. Possible values are `true` or `false`.
 - `pause_time_between_batches` - (Required) The wait time between completing the update for all virtual machines in one batch and starting the next batch. The time duration should be specified in ISO 8601 duration format.
 - `prioritize_unhealthy_instances_enabled` - (Optional) Upgrade all unhealthy instances in a scale set before any healthy instances. Possible values are `true` or `false`.
EOT
}

variable "orchestrated_virtual_machine_scale_set_single_placement_group" {
  type        = bool
  default     = null
  description = "(Optional) Should this Virtual Machine Scale Set be limited to a Single Placement Group, which means the number of instances will be capped at 100 Virtual Machines. Possible values are `true` or `false`."

  validation {
    condition     = var.orchestrated_virtual_machine_scale_set_single_placement_group != true || var.orchestrated_virtual_machine_scale_set_capacity_reservation_group_id == null
    error_message = "`single_placement_group` must be set to `false` when `capacity_reservation_group_id` is specified."
  }
}

variable "orchestrated_virtual_machine_scale_set_sku_name" {
  type        = string
  default     = null
  description = "(Optional) The `name` of the SKU to be used by this Virtual Machine Scale Set. Valid values include: any of the [General purpose](https://docs.microsoft.com/azure/virtual-machines/sizes-general), [Compute optimized](https://docs.microsoft.com/azure/virtual-machines/sizes-compute), [Memory optimized](https://docs.microsoft.com/azure/virtual-machines/sizes-memory), [Storage optimized](https://docs.microsoft.com/azure/virtual-machines/sizes-storage), [GPU optimized](https://docs.microsoft.com/azure/virtual-machines/sizes-gpu), [FPGA optimized](https://docs.microsoft.com/azure/virtual-machines/sizes-field-programmable-gate-arrays), [High performance](https://docs.microsoft.com/azure/virtual-machines/sizes-hpc), or [Previous generation](https://docs.microsoft.com/azure/virtual-machines/sizes-previous-gen) virtual machine SKUs."

  validation {
    condition     = var.orchestrated_virtual_machine_scale_set_sku_name != "Mix" || var.orchestrated_virtual_machine_scale_set_sku_profile != null
    error_message = "`sku_profile` must be configured when `sku_name` is set to `Mix`."
  }

  validation {
    condition     = var.orchestrated_virtual_machine_scale_set_sku_profile == null || var.orchestrated_virtual_machine_scale_set_sku_name == "Mix"
    error_message = "`sku_profile` can only be configured when `sku_name` is set to `Mix`."
  }
}

variable "orchestrated_virtual_machine_scale_set_sku_profile" {
  type = object({
    allocation_strategy = string
    vm_sizes            = set(string)
  })
  default     = null
  description = <<-EOT
 - `allocation_strategy` - (Required) Specifies the allocation strategy for the virtual machine scale set based on which the VMs will be allocated. Possible values are `CapacityOptimized`, `LowestPrice` and `Prioritized`.
 - `vm_sizes` - (Required) Specifies the VM sizes for the virtual machine scale set.
EOT
}

variable "orchestrated_virtual_machine_scale_set_source_image_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of an Image which each Virtual Machine in this Scale Set should be based on. Possible Image ID types include `Image ID`s, `Shared Image ID`s, `Shared Image Version ID`s, `Community Gallery Image ID`s, `Community Gallery Image Version ID`s, `Shared Gallery Image ID`s and `Shared Gallery Image Version ID`s."
}

variable "orchestrated_virtual_machine_scale_set_source_image_reference" {
  type = object({
    offer     = string
    publisher = string
    sku       = string
    version   = string
  })
  default     = null
  description = <<-EOT
 - `offer` - (Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created.
 - `publisher` - (Required) Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created.
 - `sku` - (Required) Specifies the SKU of the image used to create the virtual machines.
 - `version` - (Required) Specifies the version of the image used to create the virtual machines.
EOT
}

variable "orchestrated_virtual_machine_scale_set_tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags which should be assigned to this Virtual Machine Scale Set."
}

variable "orchestrated_virtual_machine_scale_set_termination_notification" {
  type = object({
    enabled = bool
    timeout = optional(string)
  })
  default     = null
  description = <<-EOT
 - `enabled` - (Required) Should the termination notification be enabled on this Virtual Machine Scale Set? Possible values `true` or `false`.
 - `timeout` - (Optional) Length of time (in minutes, between `5` and `15`) a notification to be sent to the VM on the instance metadata server till the VM gets deleted. The time duration should be specified in `ISO 8601` format. Defaults to `PT5M`.
EOT
}

variable "orchestrated_virtual_machine_scale_set_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` -
 - `delete` -
 - `read` -
 - `update` -
EOT
}

variable "orchestrated_virtual_machine_scale_set_upgrade_mode" {
  type        = string
  default     = null
  description = "(Optional) Specifies how upgrades (e.g. changing the Image/SKU) should be performed to Virtual Machine Instances. Possible values are `Automatic`, `Manual` and `Rolling`. Defaults to `Manual`. Changing this forces a new resource to be created."
}

variable "orchestrated_virtual_machine_scale_set_user_data_base64" {
  type        = string
  default     = null
  description = "(Optional) The Base64-Encoded User Data which should be used for this Virtual Machine Scale Set."
  ephemeral   = true

  validation {
    condition     = var.orchestrated_virtual_machine_scale_set_user_data_base64 == null || can(base64decode(var.orchestrated_virtual_machine_scale_set_user_data_base64))
    error_message = "The user_data_base64 must be a valid base64 encoded string."
  }
}

variable "orchestrated_virtual_machine_scale_set_zone_balance" {
  type        = bool
  default     = null
  description = "(Optional) Should the Virtual Machines in this Scale Set be strictly evenly distributed across Availability Zones? Defaults to `false`. Changing this forces a new resource to be created."

  validation {
    condition     = var.orchestrated_virtual_machine_scale_set_zone_balance != true || var.orchestrated_virtual_machine_scale_set_zones != null
    error_message = "`zone_balance` can only be set to `true` when availability zones are specified."
  }
}

variable "orchestrated_virtual_machine_scale_set_zones" {
  type        = set(string)
  default     = null
  description = "(Optional) Specifies a list of Availability Zones across which the Virtual Machine Scale Set will create instances."
}
