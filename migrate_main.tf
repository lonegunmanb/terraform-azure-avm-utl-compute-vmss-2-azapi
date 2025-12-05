data "azapi_resource" "existing" {
  type                   = "Microsoft.Compute/virtualMachineScaleSets@2024-11-01"
  name                   = var.orchestrated_virtual_machine_scale_set_name
  parent_id              = var.orchestrated_virtual_machine_scale_set_resource_group_id
  ignore_not_found       = true
  response_export_values = ["*"]
}

locals {
  azapi_header = merge(
    {
      type      = "Microsoft.Compute/virtualMachineScaleSets@2024-11-01"
      name      = var.orchestrated_virtual_machine_scale_set_name
      location  = var.orchestrated_virtual_machine_scale_set_location
      parent_id = var.orchestrated_virtual_machine_scale_set_resource_group_id
    },
    var.orchestrated_virtual_machine_scale_set_identity != null ? {
      identity = {
        type         = var.orchestrated_virtual_machine_scale_set_identity.type
        identity_ids = tolist(var.orchestrated_virtual_machine_scale_set_identity.identity_ids)
      }
    } : {}
  )

  existing_single_placement_group = data.azapi_resource.existing.output != null ? try(jsondecode(data.azapi_resource.existing.output).properties.singlePlacementGroup, null) : null
  single_placement_group_force_new_trigger = (
    local.existing_single_placement_group == false &&
    var.orchestrated_virtual_machine_scale_set_single_placement_group == true
  ) ? "trigger_replacement" : null

  existing_zones = data.azapi_resource.existing.output != null ? try(jsondecode(data.azapi_resource.existing.output).zones, null) : null
  zones_force_new_trigger = (
    local.existing_zones != null &&
    var.orchestrated_virtual_machine_scale_set_zones != null &&
    length(setsubtract(local.existing_zones, var.orchestrated_virtual_machine_scale_set_zones)) > 0
  ) ? "trigger_replacement" : null

  # Task #11: license_type - DiffSuppressFunc handling
  existing_license_type       = data.azapi_resource.existing.output != null ? try(jsondecode(data.azapi_resource.existing.output).properties.virtualMachineProfile.licenseType, null) : null
  normalized_license_type     = var.orchestrated_virtual_machine_scale_set_license_type == "None" ? null : var.orchestrated_virtual_machine_scale_set_license_type
  license_type_should_suppress = (
    (local.existing_license_type == "None" && local.normalized_license_type == null) ||
    (local.existing_license_type == null && local.normalized_license_type == null) ||
    (local.existing_license_type == null && var.orchestrated_virtual_machine_scale_set_license_type == "None") ||
    (local.existing_license_type == "None" && var.orchestrated_virtual_machine_scale_set_license_type == null)
  )
  license_type_update_trigger = (
    !local.license_type_should_suppress &&
    local.existing_license_type != local.normalized_license_type
  ) ? coalesce(local.normalized_license_type, "trigger") : null

  # Task #13: network_api_version - DiffSuppressFunc handling
  existing_network_api_version = data.azapi_resource.existing.output != null ? try(jsondecode(data.azapi_resource.existing.output).properties.virtualMachineProfile.networkProfile.networkApiVersion, "") : ""
  new_network_api_version = coalesce(
    var.orchestrated_virtual_machine_scale_set_network_api_version,
    "2020-11-01"
  )
  network_api_version_should_suppress = (
    var.orchestrated_virtual_machine_scale_set_sku_name == null &&
    local.existing_network_api_version == "" &&
    local.new_network_api_version == "2020-11-01"
  )
  network_api_version_update_trigger = (
    !local.network_api_version_should_suppress &&
    local.existing_network_api_version != local.new_network_api_version
  ) ? local.new_network_api_version : null

  # Task #15: proximity_placement_group_id - DiffSuppressFunc handling (case-insensitive)
  existing_proximity_placement_group_id = data.azapi_resource.existing.output != null ? try(jsondecode(data.azapi_resource.existing.output).properties.proximityPlacementGroup.id, null) : null
  proximity_placement_group_id_should_suppress = (
    local.existing_proximity_placement_group_id != null &&
    var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id != null &&
    lower(local.existing_proximity_placement_group_id) == lower(var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id)
  )
  proximity_placement_group_id_update_trigger = (
    !local.proximity_placement_group_id_should_suppress &&
    local.existing_proximity_placement_group_id != var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id
  ) ? var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id : null

  # Task #52: Map protected_settings by extension name
  extension_protected_settings_map = var.migrate_orchestrated_virtual_machine_scale_set_extension_protected_settings != null ? {
    for ext in var.migrate_orchestrated_virtual_machine_scale_set_extension_protected_settings : ext.name => jsondecode(ext.protected_settings)
  } : {}

  linux_configuration_computer_name_prefix = (
    var.orchestrated_virtual_machine_scale_set_os_profile != null &&
    var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration != null
  ) ? coalesce(
    var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.computer_name_prefix,
    var.orchestrated_virtual_machine_scale_set_name
  ) : ""

  replace_triggers_external_values = {
    location                      = { value = var.orchestrated_virtual_machine_scale_set_location }
    platform_fault_domain_count   = { value = var.orchestrated_virtual_machine_scale_set_platform_fault_domain_count }
    zone_balance                  = { value = var.orchestrated_virtual_machine_scale_set_zone_balance }
    capacity_reservation_group_id = { value = var.orchestrated_virtual_machine_scale_set_capacity_reservation_group_id }
    eviction_policy               = { value = var.orchestrated_virtual_machine_scale_set_eviction_policy }
    extension_operations_enabled  = { value = var.orchestrated_virtual_machine_scale_set_extension_operations_enabled }
    priority                      = { value = var.orchestrated_virtual_machine_scale_set_priority }
    network_interface_name        = { value = var.orchestrated_virtual_machine_scale_set_network_interface != null ? jsonencode([for nic in var.orchestrated_virtual_machine_scale_set_network_interface : nic.name]) : "" }
    single_placement_group        = local.single_placement_group_force_new_trigger
    zones                         = local.zones_force_new_trigger
    ultra_ssd_enabled             = { value = var.orchestrated_virtual_machine_scale_set_additional_capabilities != null ? coalesce(var.orchestrated_virtual_machine_scale_set_additional_capabilities.ultra_ssd_enabled, false) : false }
    data_disk_disk_encryption_set_id = { value = var.orchestrated_virtual_machine_scale_set_data_disk != null ? jsonencode([for disk in var.orchestrated_virtual_machine_scale_set_data_disk : disk.disk_encryption_set_id]) : "" }
    public_ip_prefix_id = {
      value = var.orchestrated_virtual_machine_scale_set_network_interface != null ? jsonencode([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : [
          for ip_config in nic.ip_configuration : ip_config.public_ip_address != null && length(ip_config.public_ip_address) > 0 ? ip_config.public_ip_address[0].public_ip_prefix_id : null
        ]
      ]) : ""
    }
    public_ip_sku_name = {
      value = var.orchestrated_virtual_machine_scale_set_network_interface != null ? jsonencode([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : [
          for ip_config in nic.ip_configuration : ip_config.public_ip_address != null && length(ip_config.public_ip_address) > 0 ? ip_config.public_ip_address[0].sku_name : null
        ]
      ]) : ""
    }
    public_ip_version = {
      value = var.orchestrated_virtual_machine_scale_set_network_interface != null ? jsonencode([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : [
          for ip_config in nic.ip_configuration : ip_config.public_ip_address != null && length(ip_config.public_ip_address) > 0 ? ip_config.public_ip_address[0].version : null
        ]
      ]) : ""
    }
    public_ip_ip_tag = {
      value = var.orchestrated_virtual_machine_scale_set_network_interface != null ? jsonencode([
        for nic in var.orchestrated_virtual_machine_scale_set_network_interface : [
          for ip_config in nic.ip_configuration : ip_config.public_ip_address != null && length(ip_config.public_ip_address) > 0 ? ip_config.public_ip_address[0].ip_tag : null
        ]
      ]) : ""
    }
    os_disk_storage_account_type = { value = var.orchestrated_virtual_machine_scale_set_os_disk != null ? var.orchestrated_virtual_machine_scale_set_os_disk.storage_account_type : "" }
    os_disk_disk_encryption_set_id = { value = var.orchestrated_virtual_machine_scale_set_os_disk != null ? var.orchestrated_virtual_machine_scale_set_os_disk.disk_encryption_set_id : "" }
    os_disk_diff_disk_settings_option = { value = var.orchestrated_virtual_machine_scale_set_os_disk != null && var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings != null ? var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings.option : "" }
    os_disk_diff_disk_settings_placement = { value = var.orchestrated_virtual_machine_scale_set_os_disk != null && var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings != null ? var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings.placement : "" }
    linux_configuration_admin_username   = { value = var.orchestrated_virtual_machine_scale_set_os_profile != null && var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration != null ? var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.admin_username : "" }
    linux_configuration_admin_password = { value = var.migrate_orchestrated_virtual_machine_scale_set_os_profile_linux_configuration_admin_password }
    linux_configuration_computer_name_prefix = { value = local.linux_configuration_computer_name_prefix }
    linux_configuration_provision_vm_agent = { value = var.orchestrated_virtual_machine_scale_set_os_profile != null && var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration != null ? coalesce(var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.provision_vm_agent, true) : true }
  }

  body = merge(
    {
      properties = merge(
        {
          orchestrationMode = "Flexible"
        },
        {
          platformFaultDomainCount = var.orchestrated_virtual_machine_scale_set_platform_fault_domain_count
        },
        var.orchestrated_virtual_machine_scale_set_zone_balance != null ? {
          zoneBalance = var.orchestrated_virtual_machine_scale_set_zone_balance
        } : {},
        var.orchestrated_virtual_machine_scale_set_single_placement_group != null ? {
          singlePlacementGroup = var.orchestrated_virtual_machine_scale_set_single_placement_group
        } : {},
        var.orchestrated_virtual_machine_scale_set_additional_capabilities != null ? {
          additionalCapabilities = {
            ultraSSDEnabled = var.orchestrated_virtual_machine_scale_set_additional_capabilities.ultra_ssd_enabled
          }
        } : {},
        var.orchestrated_virtual_machine_scale_set_automatic_instance_repair != null ? {
          automaticRepairsPolicy = merge(
            {
              enabled = var.orchestrated_virtual_machine_scale_set_automatic_instance_repair.enabled
            },
            var.orchestrated_virtual_machine_scale_set_automatic_instance_repair.action != null && var.orchestrated_virtual_machine_scale_set_automatic_instance_repair.action != "" ? {
              repairAction = var.orchestrated_virtual_machine_scale_set_automatic_instance_repair.action
            } : {},
            var.orchestrated_virtual_machine_scale_set_automatic_instance_repair.grace_period != null ? {
              gracePeriod = var.orchestrated_virtual_machine_scale_set_automatic_instance_repair.grace_period
            } : {}
          )
        } : {},
        var.orchestrated_virtual_machine_scale_set_sku_name != null ? {
          virtualMachineProfile = merge(
            var.orchestrated_virtual_machine_scale_set_capacity_reservation_group_id != null ? {
              capacityReservation = {
                capacityReservationGroup = {
                  id = var.orchestrated_virtual_machine_scale_set_capacity_reservation_group_id
                }
              }
            } : {},
            var.orchestrated_virtual_machine_scale_set_encryption_at_host_enabled != null ? {
              securityProfile = {
                encryptionAtHost = var.orchestrated_virtual_machine_scale_set_encryption_at_host_enabled
              }
            } : {},
            var.orchestrated_virtual_machine_scale_set_eviction_policy != null ? {
              evictionPolicy = var.orchestrated_virtual_machine_scale_set_eviction_policy
            } : {},
            {
              priority = var.orchestrated_virtual_machine_scale_set_priority
            },
            var.orchestrated_virtual_machine_scale_set_network_interface != null || var.orchestrated_virtual_machine_scale_set_sku_name != null ? {
              networkProfile = var.orchestrated_virtual_machine_scale_set_network_interface != null ? {
                networkInterfaceConfigurations = [
                    for nic in var.orchestrated_virtual_machine_scale_set_network_interface : {
                      name = nic.name # Task #61
                      properties = merge(
                        nic.auxiliary_mode != null ? {
                          auxiliaryMode = nic.auxiliary_mode
                        } : {},
                        nic.auxiliary_sku != null ? {
                          auxiliarySku = nic.auxiliary_sku
                        } : {},
                        nic.dns_servers != null ? {
                          dnsSettings = {
                            dnsServers = nic.dns_servers
                          }
                        } : {},
                        {
                          enableAcceleratedNetworking = nic.enable_accelerated_networking
                          enableIPForwarding          = nic.enable_ip_forwarding
                        },
                        nic.network_security_group_id != null && nic.network_security_group_id != "" ? {
                          networkSecurityGroup = {
                            id = nic.network_security_group_id
                          }
                        } : {},
                        {
                          primary = nic.primary
                          ipConfigurations = [
                            for ip_config in nic.ip_configuration : {
                              name = ip_config.name # Task #70
                              properties = merge(
                                ip_config.application_gateway_backend_address_pool_ids != null && length(ip_config.application_gateway_backend_address_pool_ids) > 0 ? {
                                  applicationGatewayBackendAddressPools = [
                                    for id in ip_config.application_gateway_backend_address_pool_ids : {
                                      id = id
                                    }
                                  ]
                                } : {},
                                ip_config.application_security_group_ids != null && length(ip_config.application_security_group_ids) > 0 ? {
                                  applicationSecurityGroups = [
                                    for id in ip_config.application_security_group_ids : {
                                      id = id
                                    }
                                  ]
                                } : {},
                                ip_config.load_balancer_backend_address_pool_ids != null && length(ip_config.load_balancer_backend_address_pool_ids) > 0 ? {
                                  loadBalancerBackendAddressPools = [
                                    for id in ip_config.load_balancer_backend_address_pool_ids : {
                                      id = id
                                    }
                                  ]
                                } : {},
                                merge(
                                  {
                                    primary = ip_config.primary
                                  },
                                  ip_config.subnet_id != null && ip_config.subnet_id != "" ? {
                                    subnet = {
                                      id = ip_config.subnet_id
                                    }
                                  } : {},
                                  {
                                    privateIPAddressVersion = ip_config.version
                                  },
                                  ip_config.public_ip_address != null && length(ip_config.public_ip_address) > 0 ? {
                                    publicIPAddressConfiguration = merge(
                                      {
                                        name = ip_config.public_ip_address[0].name
                                      },
                                       ip_config.public_ip_address[0].domain_name_label != null && ip_config.public_ip_address[0].domain_name_label != "" ? {
                                        properties = merge(
                                          {
                                            dnsSettings = {
                                              domainNameLabel = ip_config.public_ip_address[0].domain_name_label
                                            }
                                          },
                                          ip_config.public_ip_address[0].idle_timeout_in_minutes != null && ip_config.public_ip_address[0].idle_timeout_in_minutes > 0 ? {
                                            idleTimeoutInMinutes = ip_config.public_ip_address[0].idle_timeout_in_minutes
                                          } : {},
                                          ip_config.public_ip_address[0].public_ip_prefix_id != null && ip_config.public_ip_address[0].public_ip_prefix_id != "" ? {
                                            publicIPPrefix = {
                                              id = ip_config.public_ip_address[0].public_ip_prefix_id
                                            }
                                          } : {},
                                          {
                                            publicIPAddressVersion = ip_config.public_ip_address[0].version
                                          },
                                          ip_config.public_ip_address[0].ip_tag != null && length(ip_config.public_ip_address[0].ip_tag) > 0 ? {
                                            ipTags = [
                                              for ip_tag in ip_config.public_ip_address[0].ip_tag : {
                                                tag       = ip_tag.tag
                                                ipTagType = ip_tag.type
                                              }
                                            ]
                                          } : {}
                                        )
                                      } : ip_config.public_ip_address[0].idle_timeout_in_minutes != null && ip_config.public_ip_address[0].idle_timeout_in_minutes > 0 ? {
                                        properties = merge(
                                          {
                                            idleTimeoutInMinutes = ip_config.public_ip_address[0].idle_timeout_in_minutes
                                          },
                                          ip_config.public_ip_address[0].public_ip_prefix_id != null && ip_config.public_ip_address[0].public_ip_prefix_id != "" ? {
                                            publicIPPrefix = {
                                              id = ip_config.public_ip_address[0].public_ip_prefix_id
                                            }
                                          } : {},
                                          {
                                            publicIPAddressVersion = ip_config.public_ip_address[0].version
                                          },
                                          ip_config.public_ip_address[0].ip_tag != null && length(ip_config.public_ip_address[0].ip_tag) > 0 ? {
                                            ipTags = [
                                              for ip_tag in ip_config.public_ip_address[0].ip_tag : {
                                                tag       = ip_tag.tag
                                                ipTagType = ip_tag.type
                                              }
                                            ]
                                          } : {}
                                        )
                                      } : ip_config.public_ip_address[0].public_ip_prefix_id != null && ip_config.public_ip_address[0].public_ip_prefix_id != "" ? {
                                        properties = merge(
                                          {
                                            publicIPPrefix = {
                                              id = ip_config.public_ip_address[0].public_ip_prefix_id
                                            }
                                          },
                                          {
                                            publicIPAddressVersion = ip_config.public_ip_address[0].version
                                          },
                                          ip_config.public_ip_address[0].ip_tag != null && length(ip_config.public_ip_address[0].ip_tag) > 0 ? {
                                            ipTags = [
                                              for ip_tag in ip_config.public_ip_address[0].ip_tag : {
                                                tag       = ip_tag.tag
                                                ipTagType = ip_tag.type
                                              }
                                            ]
                                          } : {}
                                        )
                                      } : {
                                        properties = merge(
                                          {
                                            publicIPAddressVersion = ip_config.public_ip_address[0].version
                                          },
                                          ip_config.public_ip_address[0].ip_tag != null && length(ip_config.public_ip_address[0].ip_tag) > 0 ? {
                                            ipTags = [
                                              for ip_tag in ip_config.public_ip_address[0].ip_tag : {
                                                tag       = ip_tag.tag
                                                ipTagType = ip_tag.type
                                              }
                                            ]
                                          } : {}
                                        )
                                      },
                                      ip_config.public_ip_address[0].sku_name != null && ip_config.public_ip_address[0].sku_name != "" ? {
                                        sku = {
                                          name = split("_", ip_config.public_ip_address[0].sku_name)[0]
                                          tier = split("_", ip_config.public_ip_address[0].sku_name)[1]
                                        }
                                      } : {}
                                    )
                                  } : {}
                                )
                              )
                            }
                          ]
                        }
                      )
                    }
                  ]
                } : {}
            } : {},
            var.orchestrated_virtual_machine_scale_set_boot_diagnostics != null ? {
              diagnosticsProfile = {
                bootDiagnostics = merge(
                  {
                    enabled = true
                  },
                  var.orchestrated_virtual_machine_scale_set_boot_diagnostics.storage_account_uri != null ? {
                    storageUri = var.orchestrated_virtual_machine_scale_set_boot_diagnostics.storage_account_uri
                    } : {
                    storageUri = ""
                  }
                )
              }
            } : {},
            var.orchestrated_virtual_machine_scale_set_os_profile != null ? {
              osProfile = merge(
                {
                  allowExtensionOperations = var.orchestrated_virtual_machine_scale_set_extension_operations_enabled
                },
                var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration != null ? merge(
                  {
                    computerNamePrefix = local.linux_configuration_computer_name_prefix
                  },
                  {
                    linuxConfiguration = merge(
                      {
                        adminUsername                 = var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.admin_username
                        disablePasswordAuthentication = var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.disable_password_authentication
                        provisionVMAgent              = coalesce(var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.provision_vm_agent, true)
                        # ssh = { # Task #106-108
                        #   publicKeys = ... # Task #106-108
                        # }
                        # secrets = ... # Task #109-112
                      },
                      {
                        patchSettings = {
                          assessmentMode = var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.patch_assessment_mode
                          patchMode      = var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration.patch_mode
                        }
                      }
                    )
                  }
                ) : {},
                var.orchestrated_virtual_machine_scale_set_os_profile.windows_configuration != null ? {
                  windowsConfiguration = merge(
                    {
                      enableAutomaticUpdates = var.orchestrated_virtual_machine_scale_set_os_profile.windows_configuration.enable_automatic_updates
                    },
                    {
                      # adminUsername = ... # Handled at parent osProfile level - Task #115
                      # computerNamePrefix = ... # Handled at parent osProfile level - Task #116
                      # provisionVMAgent = ... # Task #121
                      # timeZone = ... # Task #122
                      # patchSettings = { # Task #118, #119, #120
                      #   assessmentMode = ... # Task #119
                      #   patchMode = ... # Task #120
                      #   enableHotpatching = ... # Task #118
                      # }
                      # additionalUnattendContent = ... # Task #123-125
                      # winRM = { # Task #131-133
                      #   listeners = ... # Task #131-133
                      # }
                      # secrets = ... # Task #126-130
                    }
                  )
                } : {}
              )
            } : {},
            var.orchestrated_virtual_machine_scale_set_max_bid_price > 0 ? {
              billingProfile = {
                maxPrice = var.orchestrated_virtual_machine_scale_set_max_bid_price
              }
            } : {},
            var.orchestrated_virtual_machine_scale_set_extension != null || var.orchestrated_virtual_machine_scale_set_extensions_time_budget != null ? {
              extensionProfile = merge(
                var.orchestrated_virtual_machine_scale_set_extension != null ? {
                  extensions = [
                    for ext in var.orchestrated_virtual_machine_scale_set_extension : {
                      name = ext.name
                      properties = merge(
                        {
                          publisher               = ext.publisher
                          type                    = ext.type
                          typeHandlerVersion      = ext.type_handler_version
                          autoUpgradeMinorVersion = ext.auto_upgrade_minor_version_enabled
                        },
                        ext.extensions_to_provision_after_vm_creation != null ? {
                          provisionAfterExtensions = ext.extensions_to_provision_after_vm_creation
                        } : {},
                        {
                          suppressFailures = ext.failure_suppression_enabled
                        },
                        ext.force_extension_execution_on_change != null ? {
                          forceUpdateTag = ext.force_extension_execution_on_change
                        } : {},
                        ext.settings != null && ext.settings != "" ? {
                          settings = jsondecode(ext.settings)
                        } : {},
                        # protectedSettings = ... # Task #52
                        ext.protected_settings_from_key_vault != null ? {
                          protectedSettingsFromKeyVault = {
                            secretUrl = ext.protected_settings_from_key_vault.secret_url
                            sourceVault = {
                              id = ext.protected_settings_from_key_vault.source_vault_id
                            }
                          }
                        } : {}
                      }
                    }
                  ]
                } : {},
                var.orchestrated_virtual_machine_scale_set_extensions_time_budget != null ? {
                  extensionsTimeBudget = var.orchestrated_virtual_machine_scale_set_extensions_time_budget
                } : {}
              )
            } : {},
            var.orchestrated_virtual_machine_scale_set_data_disk != null || var.orchestrated_virtual_machine_scale_set_os_disk != null ? {
              storageProfile = merge(
                var.orchestrated_virtual_machine_scale_set_data_disk != null ? {
                  dataDisks = [
                    for data_disk in var.orchestrated_virtual_machine_scale_set_data_disk : {
                      caching = data_disk.caching
                      managedDisk = merge(
                        {
                          storageAccountType = data_disk.storage_account_type
                        },
                        data_disk.disk_encryption_set_id != null && data_disk.disk_encryption_set_id != "" ? {
                          diskEncryptionSet = {
                            id = data_disk.disk_encryption_set_id
                          }
                        } : {}
                      )
                      createOption = data_disk.create_option
                      diskSizeGB              = data_disk.disk_size_gb != null && data_disk.disk_size_gb > 0 ? data_disk.disk_size_gb : null
                      lun                     = data_disk.lun
                      writeAcceleratorEnabled = data_disk.write_accelerator_enabled
                      diskIOPSReadWrite       = data_disk.ultra_ssd_disk_iops_read_write != null && data_disk.ultra_ssd_disk_iops_read_write > 0 ? data_disk.ultra_ssd_disk_iops_read_write : null
                      diskMBpsReadWrite = data_disk.ultra_ssd_disk_mbps_read_write != null && data_disk.ultra_ssd_disk_mbps_read_write > 0 ? data_disk.ultra_ssd_disk_mbps_read_write : null
                    }
                  ]
                } : {},
                var.orchestrated_virtual_machine_scale_set_os_disk != null ? {
                  osDisk = merge(
                    {
                      caching = var.orchestrated_virtual_machine_scale_set_os_disk.caching
                      managedDisk = merge(
                        {
                          storageAccountType = var.orchestrated_virtual_machine_scale_set_os_disk.storage_account_type
                        },
                        var.orchestrated_virtual_machine_scale_set_os_disk.disk_encryption_set_id != null && var.orchestrated_virtual_machine_scale_set_os_disk.disk_encryption_set_id != "" ? {
                          diskEncryptionSet = {
                            id = var.orchestrated_virtual_machine_scale_set_os_disk.disk_encryption_set_id
                          }
                        } : {}
                      )
                      diskSizeGB = var.orchestrated_virtual_machine_scale_set_os_disk.disk_size_gb != null && var.orchestrated_virtual_machine_scale_set_os_disk.disk_size_gb > 0 ? var.orchestrated_virtual_machine_scale_set_os_disk.disk_size_gb : null
                      writeAcceleratorEnabled = var.orchestrated_virtual_machine_scale_set_os_disk.write_accelerator_enabled
                    },
                    var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings != null ? {
                      diffDiskSettings = {
                        option = var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings.option
                        placement = var.orchestrated_virtual_machine_scale_set_os_disk.diff_disk_settings.placement
                      }
                    } : {}
                  )
                } : {}
              )
            } : {}
          )
        } : {}
      )
    },
    var.orchestrated_virtual_machine_scale_set_sku_name != null ? {
      sku = {
        name     = var.orchestrated_virtual_machine_scale_set_sku_name
        capacity = var.orchestrated_virtual_machine_scale_set_instances
        tier     = var.orchestrated_virtual_machine_scale_set_sku_name != "Mix" ? "Standard" : null
      }
    } : {},
    var.orchestrated_virtual_machine_scale_set_zones != null && length(var.orchestrated_virtual_machine_scale_set_zones) > 0 ? {
      zones = tolist(var.orchestrated_virtual_machine_scale_set_zones)
    } : {}
  )

  sensitive_body = {
    properties = merge(
      var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id != null ? {
        proximityPlacementGroup = {
          id = var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id
        }
      } : {},
      var.orchestrated_virtual_machine_scale_set_sku_name != null ? {
        virtualMachineProfile = merge(
          var.orchestrated_virtual_machine_scale_set_user_data_base64 != null ? {
            userData = var.orchestrated_virtual_machine_scale_set_user_data_base64
          } : {},
          local.normalized_license_type != null ? {
            licenseType = local.normalized_license_type
          } : {},
          var.orchestrated_virtual_machine_scale_set_os_profile != null ? {
            osProfile = merge(
              var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data != null ? {
                customData = var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data
              } : {},
              var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration != null && var.migrate_orchestrated_virtual_machine_scale_set_os_profile_linux_configuration_admin_password != null ? {
                adminPassword = var.migrate_orchestrated_virtual_machine_scale_set_os_profile_linux_configuration_admin_password
              } : {}
            )
          } : {},
          var.orchestrated_virtual_machine_scale_set_extension != null && length(local.extension_protected_settings_map) > 0 ? {
            extensionProfile = {
              extensions = [
                for ext in var.orchestrated_virtual_machine_scale_set_extension : {
                  name = ext.name
                  properties = lookup(local.extension_protected_settings_map, ext.name, null) != null ? {
                    protectedSettings = local.extension_protected_settings_map[ext.name]
                  } : {}
                }
              ]
            }
          } : {},
          var.orchestrated_virtual_machine_scale_set_network_interface != null || var.orchestrated_virtual_machine_scale_set_sku_name != null ? {
            networkProfile = {
              networkApiVersion = local.new_network_api_version
            }
          } : {}
        )
      } : {}
    )
  }

  sensitive_body_version = {
    "properties.proximityPlacementGroup.id"                                            = "null"
    "properties.virtualMachineProfile.osProfile.customData"                            = try(tostring(var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data_version), "null")
    "properties.virtualMachineProfile.osProfile.adminPassword"                         = try(tostring(var.migrate_orchestrated_virtual_machine_scale_set_os_profile_linux_configuration_admin_password_version), "null")
    "properties.virtualMachineProfile.userData"                                        = try(tostring(var.orchestrated_virtual_machine_scale_set_user_data_base64_version), "null")
    "properties.virtualMachineProfile.licenseType"                                     = "null"
    "properties.virtualMachineProfile.networkProfile.networkApiVersion"                = "null"
    "properties.virtualMachineProfile.extensionProfile.protectedSettings"              = try(tostring(var.migrate_orchestrated_virtual_machine_scale_set_extension_protected_settings_version), "null")
  }

  post_creation_updates = compact([
    {
      azapi_header = {
        type      = "Microsoft.Compute/virtualMachineScaleSets@2024-11-01"
        name      = var.orchestrated_virtual_machine_scale_set_name
        parent_id = var.orchestrated_virtual_machine_scale_set_resource_group_id
      }
      body = {
        properties = merge(
          var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id != null ? {
            proximityPlacementGroup = {
              id = var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id
            }
          } : {},
          {
            virtualMachineProfile = merge(
              local.normalized_license_type != null ? {
                licenseType = local.normalized_license_type
              } : {},
              var.orchestrated_virtual_machine_scale_set_network_interface != null || var.orchestrated_virtual_machine_scale_set_sku_name != null ? {
                networkProfile = {
                  networkApiVersion = local.new_network_api_version
                }
              } : {}
            )
          }
        )
      }
      replace_triggers_external_values = {
        proximity_placement_group_id = local.proximity_placement_group_id_update_trigger
        license_type                 = local.license_type_update_trigger
        network_api_version          = local.network_api_version_update_trigger
      }
    }
  ])

  locks = []
}
