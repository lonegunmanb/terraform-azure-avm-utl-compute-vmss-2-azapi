data "azapi_resource" "existing" {
  type                   = "Microsoft.Compute/virtualMachineScaleSets@2024-11-01"
  name                   = var.name
  parent_id              = var.resource_group_id
  ignore_not_found       = true
  response_export_values = ["*"]
}

locals {
  azapi_header = merge(
    {
      type                 = "Microsoft.Compute/virtualMachineScaleSets@2024-11-01"
      name                 = var.name
      location             = var.location
      parent_id            = var.resource_group_id
      tags                 = var.tags
      ignore_null_property = true
    },
    var.identity != null ? {
      identity = {
        type         = var.identity.type
        identity_ids = tolist(var.identity.identity_ids)
      }
    } : {}
  )

  existing_single_placement_group = data.azapi_resource.existing.exists ? try(data.azapi_resource.existing.output.properties.singlePlacementGroup, null) : null
  single_placement_group_force_new_trigger = (
    local.existing_single_placement_group == false &&
    var.single_placement_group == true
  ) ? "trigger_replacement" : null

  existing_zones = data.azapi_resource.existing.exists ? try(data.azapi_resource.existing.output.zones, null) : null
  zones_force_new_trigger = (
    local.existing_zones != null &&
    var.zones != null &&
    length(setsubtract(local.existing_zones, var.zones)) > 0
  ) ? "trigger_replacement" : null

  # Task #11: license_type - DiffSuppressFunc handling
  existing_license_type       = data.azapi_resource.existing.exists ? try(data.azapi_resource.existing.output.properties.virtualMachineProfile.licenseType, null) : null
  normalized_license_type     = var.license_type == "None" ? null : var.license_type
  license_type_should_suppress = (
    (local.existing_license_type == "None" && local.normalized_license_type == null) ||
    (local.existing_license_type == null && local.normalized_license_type == null) ||
    (local.existing_license_type == null && var.license_type == "None") ||
    (local.existing_license_type == "None" && var.license_type == null)
  )
  license_type_update_trigger = (
    !local.license_type_should_suppress &&
    local.existing_license_type != local.normalized_license_type
  ) ? coalesce(local.normalized_license_type, "trigger") : null

  # Task #13: network_api_version - DiffSuppressFunc handling
  existing_network_api_version = data.azapi_resource.existing.exists ? try(data.azapi_resource.existing.output.properties.virtualMachineProfile.networkProfile.networkApiVersion, "") : ""
  new_network_api_version = coalesce(
    var.network_api_version,
    "2020-11-01"
  )
  network_api_version_should_suppress = (
    var.sku_name == null &&
    local.existing_network_api_version == "" &&
    local.new_network_api_version == "2020-11-01"
  )
  network_api_version_update_trigger = (
    !local.network_api_version_should_suppress &&
    local.existing_network_api_version != local.new_network_api_version
  ) ? local.new_network_api_version : null

  # Task #15: proximity_placement_group_id - DiffSuppressFunc handling (case-insensitive)
  existing_proximity_placement_group_id = data.azapi_resource.existing.exists ? try(data.azapi_resource.existing.output.properties.proximityPlacementGroup.id, null) : null
  proximity_placement_group_id_should_suppress = (
    local.existing_proximity_placement_group_id != null &&
    var.proximity_placement_group_id != null &&
    lower(local.existing_proximity_placement_group_id) == lower(var.proximity_placement_group_id)
  )
  proximity_placement_group_id_update_trigger = (
    !local.proximity_placement_group_id_should_suppress &&
    local.existing_proximity_placement_group_id != var.proximity_placement_group_id
  ) ? var.proximity_placement_group_id : null

  # Task #52: Map protected_settings by extension name
  extension_protected_settings_map = var.extension_protected_settings != null ? {
    for ext in var.extension_protected_settings : ext.name => jsondecode(ext.protected_settings)
  } : {}

  linux_configuration_computer_name_prefix = (
    var.os_profile != null &&
    var.os_profile.linux_configuration != null
  ) ? coalesce(
    var.os_profile.linux_configuration.computer_name_prefix,
    var.name
  ) : ""

  windows_configuration_computer_name_prefix = (
    var.os_profile != null &&
    var.os_profile.windows_configuration != null
  ) ? coalesce(
    var.os_profile.windows_configuration.computer_name_prefix,
    var.name
  ) : ""

  # Task #124: Map content by index for additional_unattend_content
  additional_unattend_content_map = var.os_profile_windows_configuration_additional_unattend_content_content != null ? {
    for item in var.os_profile_windows_configuration_additional_unattend_content_content : item.index => item.content
  } : {}

  replace_triggers_external_values = {
    location                      = { value = var.location }
    platform_fault_domain_count   = { value = var.platform_fault_domain_count }
    zone_balance                  = { value = var.zone_balance }
    capacity_reservation_group_id = { value = var.capacity_reservation_group_id }
    eviction_policy               = { value = var.eviction_policy }
    extension_operations_enabled  = { value = var.extension_operations_enabled }
    priority                      = { value = var.priority }
    network_interface_name        = { value = var.network_interface != null ? jsonencode([for nic in var.network_interface : nic.name]) : "" }
    single_placement_group        = local.single_placement_group_force_new_trigger
    zones                         = local.zones_force_new_trigger
    ultra_ssd_enabled             = { value = var.additional_capabilities != null ? coalesce(var.additional_capabilities.ultra_ssd_enabled, false) : false }
    data_disk_disk_encryption_set_id = { value = var.data_disk != null ? jsonencode([for disk in var.data_disk : disk.disk_encryption_set_id]) : "" }
    public_ip_prefix_id = {
      value = var.network_interface != null ? jsonencode([
        for nic in var.network_interface : [
          for ip_config in nic.ip_configuration : ip_config.public_ip_address != null && length(ip_config.public_ip_address) > 0 ? ip_config.public_ip_address[0].public_ip_prefix_id : null
        ]
      ]) : ""
    }
    public_ip_sku_name = {
      value = var.network_interface != null ? jsonencode([
        for nic in var.network_interface : [
          for ip_config in nic.ip_configuration : ip_config.public_ip_address != null && length(ip_config.public_ip_address) > 0 ? ip_config.public_ip_address[0].sku_name : null
        ]
      ]) : ""
    }
    public_ip_version = {
      value = var.network_interface != null ? jsonencode([
        for nic in var.network_interface : [
          for ip_config in nic.ip_configuration : ip_config.public_ip_address != null && length(ip_config.public_ip_address) > 0 ? ip_config.public_ip_address[0].version : null
        ]
      ]) : ""
    }
    public_ip_ip_tag = {
      value = var.network_interface != null ? jsonencode([
        for nic in var.network_interface : [
          for ip_config in nic.ip_configuration : ip_config.public_ip_address != null && length(ip_config.public_ip_address) > 0 ? ip_config.public_ip_address[0].ip_tag : null
        ]
      ]) : ""
    }
    os_disk_storage_account_type = { value = var.os_disk != null ? var.os_disk.storage_account_type : "" }
    os_disk_disk_encryption_set_id = { value = var.os_disk != null ? var.os_disk.disk_encryption_set_id : "" }
    os_disk_diff_disk_settings_option = { value = var.os_disk != null && var.os_disk.diff_disk_settings != null ? var.os_disk.diff_disk_settings.option : "" }
    os_disk_diff_disk_settings_placement = { value = var.os_disk != null && var.os_disk.diff_disk_settings != null ? var.os_disk.diff_disk_settings.placement : "" }
    linux_configuration_admin_username   = { value = var.os_profile != null && var.os_profile.linux_configuration != null ? var.os_profile.linux_configuration.admin_username : "" }
    linux_configuration_admin_password_version = { value = var.os_profile_linux_configuration_admin_password_version }
    linux_configuration_computer_name_prefix = { value = local.linux_configuration_computer_name_prefix }
    linux_configuration_provision_vm_agent = { value = var.os_profile != null && var.os_profile.linux_configuration != null ? coalesce(var.os_profile.linux_configuration.provision_vm_agent, true) : true }
    windows_configuration_admin_password_version = { value = var.os_profile_windows_configuration_admin_password_version }
    windows_configuration_admin_username = { value = var.os_profile != null && var.os_profile.windows_configuration != null ? var.os_profile.windows_configuration.admin_username : "" }
    windows_configuration_computer_name_prefix = { value = local.windows_configuration_computer_name_prefix }
    windows_configuration_provision_vm_agent = { value = var.os_profile != null && var.os_profile.windows_configuration != null ? var.os_profile.windows_configuration.provision_vm_agent : true }
    windows_configuration_winrm_listener_protocol = {
      value = var.os_profile != null && var.os_profile.windows_configuration != null && var.os_profile.windows_configuration.winrm_listener != null ? jsonencode([for listener in var.os_profile.windows_configuration.winrm_listener : listener.protocol]) : ""
    }
    windows_configuration_winrm_listener_certificate_url = {
      value = var.os_profile != null && var.os_profile.windows_configuration != null && var.os_profile.windows_configuration.winrm_listener != null ? jsonencode([for listener in var.os_profile.windows_configuration.winrm_listener : listener.certificate_url]) : ""
    }
    plan_name = { value = var.plan != null ? var.plan.name : "" }
    plan_product = { value = var.plan != null ? var.plan.product : "" }
    plan_publisher = { value = var.plan != null ? var.plan.publisher : "" }
    priority_mix_base_regular_count = { value = var.priority_mix != null ? var.priority_mix.base_regular_count : 0 }
    priority_mix_regular_percentage_above_base = { value = var.priority_mix != null ? var.priority_mix.regular_percentage_above_base : 0 }
    rolling_upgrade_policy = { value = var.rolling_upgrade_policy != null ? jsonencode(var.rolling_upgrade_policy) : "" }
    sku_profile_allocation_strategy     = { value = var.sku_profile != null ? var.sku_profile.allocation_strategy : "" }
    sku_profile_vm_sizes                = { value = var.sku_profile != null ? jsonencode(var.sku_profile.vm_sizes) : "" }
    source_image_reference_offer        = { value = var.source_image_reference != null ? var.source_image_reference.offer : "" }
    source_image_reference_publisher    = { value = var.source_image_reference != null ? var.source_image_reference.publisher : "" }
  }

  body = merge(
    {
      properties = merge(
        {
          orchestrationMode = "Flexible"
        },
        {
          platformFaultDomainCount = var.platform_fault_domain_count
        },
        var.zone_balance != null ? {
          zoneBalance = var.zone_balance
        } : {},
        var.single_placement_group != null ? {
          singlePlacementGroup = var.single_placement_group
        } : {},
        var.additional_capabilities != null ? {
          additionalCapabilities = {
            ultraSSDEnabled = var.additional_capabilities.ultra_ssd_enabled
          }
        } : {},
        var.automatic_instance_repair != null ? {
          automaticRepairsPolicy = merge(
            {
              enabled = var.automatic_instance_repair.enabled
            },
            var.automatic_instance_repair.action != null && var.automatic_instance_repair.action != "" ? {
              repairAction = var.automatic_instance_repair.action
            } : {},
            var.automatic_instance_repair.grace_period != null ? {
              gracePeriod = var.automatic_instance_repair.grace_period
            } : {}
          )
        } : {},
        var.priority_mix != null ? {
          priorityMixPolicy = {
            baseRegularPriorityCount = var.priority_mix.base_regular_count
            regularPriorityPercentageAboveBase = var.priority_mix.regular_percentage_above_base
          }
        } : {},
        var.rolling_upgrade_policy != null ? {
          upgradePolicy = {
            rollingUpgradePolicy = merge(
              {
                maxBatchInstancePercent = var.rolling_upgrade_policy.max_batch_instance_percent
                maxUnhealthyInstancePercent = var.rolling_upgrade_policy.max_unhealthy_instance_percent
                maxUnhealthyUpgradedInstancePercent = var.rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent
                pauseTimeBetweenBatches = var.rolling_upgrade_policy.pause_time_between_batches
              },
              (var.zones != null && length(var.zones) > 0) ? {
                enableCrossZoneUpgrade = coalesce(var.rolling_upgrade_policy.cross_zone_upgrades_enabled, false)
              } : {},
              {
                maxSurge = var.rolling_upgrade_policy.maximum_surge_instances_enabled
              },
              var.rolling_upgrade_policy.prioritize_unhealthy_instances_enabled != null ? {
                prioritizeUnhealthyInstances = var.rolling_upgrade_policy.prioritize_unhealthy_instances_enabled
              } : {}
            )
          }
        } : {},
        var.sku_profile != null ? {
          skuProfile = {
            allocationStrategy = var.sku_profile.allocation_strategy
            vmSizes = [
              for vm_size in var.sku_profile.vm_sizes : {
                name = vm_size
              }
            ]
          }
        } : {},
        var.sku_name != null ? {
          virtualMachineProfile = merge(
            var.capacity_reservation_group_id != null ? {
              capacityReservation = {
                capacityReservationGroup = {
                  id = var.capacity_reservation_group_id
                }
              }
            } : {},
            var.encryption_at_host_enabled != null ? {
              securityProfile = {
                encryptionAtHost = var.encryption_at_host_enabled
              }
            } : {},
            var.eviction_policy != null ? {
              evictionPolicy = var.eviction_policy
            } : {},
            {
              priority = var.priority
            },
            var.network_interface != null || var.sku_name != null ? {
              networkProfile = var.network_interface != null ? {
                networkInterfaceConfigurations = [
                    for nic in var.network_interface : {
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
                                      {
                                        properties = merge(
                                          ip_config.public_ip_address[0].domain_name_label != null && ip_config.public_ip_address[0].domain_name_label != "" ? {
                                            dnsSettings = {
                                              domainNameLabel = ip_config.public_ip_address[0].domain_name_label
                                            }
                                          } : {},
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
            var.boot_diagnostics != null ? {
              diagnosticsProfile = {
                bootDiagnostics = merge(
                  {
                    enabled = true
                  },
                  var.boot_diagnostics.storage_account_uri != null ? {
                    storageUri = var.boot_diagnostics.storage_account_uri
                    } : {
                    storageUri = ""
                  }
                )
              }
            } : {},
            var.os_profile != null ? {
              osProfile = merge(
                {
                  allowExtensionOperations = var.extension_operations_enabled
                },
                var.os_profile.linux_configuration != null ? {
                  computerNamePrefix = local.linux_configuration_computer_name_prefix
                } : {},
                var.os_profile.linux_configuration != null ? {
                  linuxConfiguration = merge(
                    {
                      disablePasswordAuthentication = var.os_profile.linux_configuration.disable_password_authentication
                      provisionVMAgent              = coalesce(var.os_profile.linux_configuration.provision_vm_agent, true)
                    },
                    var.os_profile.linux_configuration.admin_ssh_key != null && length(var.os_profile.linux_configuration.admin_ssh_key) > 0 ? {
                      ssh = {
                        publicKeys = [
                          for ssh_key in var.os_profile.linux_configuration.admin_ssh_key : {
                            keyData = ssh_key.public_key
                            path    = "/home/${ssh_key.username}/.ssh/authorized_keys"
                          }
                        ]
                      }
                    } : {},
                    {
                      patchSettings = {
                        assessmentMode = var.os_profile.linux_configuration.patch_assessment_mode
                        patchMode      = var.os_profile.linux_configuration.patch_mode
                      }
                    }
                  )
                } : {},
                var.os_profile.linux_configuration != null ? {
                  adminUsername = var.os_profile.linux_configuration.admin_username
                } : {},
                var.os_profile.linux_configuration != null && var.os_profile.linux_configuration.secret != null && length(var.os_profile.linux_configuration.secret) > 0 ? {
                  secrets = [
                    for secret in var.os_profile.linux_configuration.secret : {
                      sourceVault = {
                        id = secret.key_vault_id
                      }
                      vaultCertificates = [
                        for certificate in secret.certificate : {
                          certificateUrl = certificate.url
                        }
                      ]
                    }
                  ]
                } : {},
                var.os_profile.windows_configuration != null ? {
                  computerNamePrefix = local.windows_configuration_computer_name_prefix
                } : {},
                var.os_profile.windows_configuration != null ? {
                  windowsConfiguration = merge(
                    {
                      enableAutomaticUpdates = var.os_profile.windows_configuration.enable_automatic_updates
                    },
                    {
                      patchSettings = merge(
                        {
                          enableHotpatching = var.os_profile.windows_configuration.hotpatching_enabled
                        },
                        var.os_profile.windows_configuration.patch_assessment_mode != null ? {
                          assessmentMode = var.os_profile.windows_configuration.patch_assessment_mode
                        } : {},
                        {
                          patchMode = var.os_profile.windows_configuration.patch_mode
                        }
                      )
                    },
                    {
                      provisionVMAgent = var.os_profile.windows_configuration.provision_vm_agent
                    },
                    var.os_profile.windows_configuration.timezone != null && var.os_profile.windows_configuration.timezone != "" ? {
                      timeZone = var.os_profile.windows_configuration.timezone
                    } : {},
                    var.os_profile.windows_configuration.additional_unattend_content != null ? {
                      additionalUnattendContent = [
                        for idx, content in var.os_profile.windows_configuration.additional_unattend_content : {
                          componentName = "Microsoft-Windows-Shell-Setup"
                          passName      = "OobeSystem"
                          # content = ... # Task #124 - in sensitive_body
                          settingName = content.setting
                        }
                      ]
                    } : {},
                    var.os_profile.windows_configuration.winrm_listener != null && length(var.os_profile.windows_configuration.winrm_listener) > 0 ? {
                      winRM = {
                        listeners = [
                          for listener in var.os_profile.windows_configuration.winrm_listener : merge(
                            {
                              protocol = listener.protocol
                            },
                            listener.certificate_url != null ? {
                              certificateUrl = listener.certificate_url
                            } : {}
                          )
                        ]
                      }
                    } : {}
                  )
                } : {},
                var.os_profile.windows_configuration != null &&
                var.os_profile.windows_configuration.secret != null &&
                length(var.os_profile.windows_configuration.secret) > 0 ? {
                  secrets = [
                    for secret in var.os_profile.windows_configuration.secret : {
                      sourceVault = {
                        id = secret.key_vault_id
                      }
                      vaultCertificates = [
                        for cert in secret.certificate : {
                          certificateStore = cert.store
                          certificateUrl   = cert.url
                        }
                      ]
                    }
                  ]
                } : {},
                var.os_profile.windows_configuration != null ? {
                  adminUsername = var.os_profile.windows_configuration.admin_username
                } : {}
              )
            } : {},
            var.max_bid_price > 0 ? {
              billingProfile = {
                maxPrice = var.max_bid_price
              }
            } : {},
            var.extension != null || var.extensions_time_budget != null ? {
              extensionProfile = merge(
                var.extension != null ? {
                  extensions = [
                    for ext in var.extension : {
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
                      )
                    }
                  ]
                } : {},
                var.extensions_time_budget != null ? {
                  extensionsTimeBudget = var.extensions_time_budget
                } : {}
              )
            } : {},
            var.termination_notification != null ? {
              scheduledEventsProfile = {
                terminateNotificationProfile = {
                  enable           = var.termination_notification.enabled
                  notBeforeTimeout = var.termination_notification.timeout
                }
              }
            } : {},
            var.data_disk != null || var.os_disk != null || var.source_image_reference != null ? {
              storageProfile = merge(
                var.data_disk != null ? {
                  dataDisks = [
                    for data_disk in var.data_disk : {
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
                var.os_disk != null ? {
                  osDisk = merge(
                    {
                      createOption = "FromImage"
                      caching = var.os_disk.caching
                      managedDisk = merge(
                        {
                          storageAccountType = var.os_disk.storage_account_type
                        },
                        var.os_disk.disk_encryption_set_id != null && var.os_disk.disk_encryption_set_id != "" ? {
                          diskEncryptionSet = {
                            id = var.os_disk.disk_encryption_set_id
                          }
                        } : {}
                      )
                      diskSizeGB = var.os_disk.disk_size_gb != null && var.os_disk.disk_size_gb > 0 ? var.os_disk.disk_size_gb : null
                      writeAcceleratorEnabled = var.os_disk.write_accelerator_enabled
                    },
                    var.os_disk.diff_disk_settings != null ? {
                      diffDiskSettings = {
                        option = var.os_disk.diff_disk_settings.option
                        placement = var.os_disk.diff_disk_settings.placement
                      }
                    } : {}
                  )
                } : {},
                var.source_image_reference != null ? {
                  imageReference = {
                    offer     = var.source_image_reference.offer
                    publisher = var.source_image_reference.publisher
                    sku       = var.source_image_reference.sku
                    version   = var.source_image_reference.version
                  }
                } : {}
              )
            } : {}
          )
        } : {}
      )
    },
    var.sku_name != null ? {
      sku = {
        name     = var.sku_name
        capacity = var.instances
        tier     = var.sku_name != "Mix" ? "Standard" : null
      }
    } : {},
    var.zones != null && length(var.zones) > 0 ? {
      zones = tolist(var.zones)
    } : {},
    var.plan != null ? {
      plan = {
        name = var.plan.name
        product = var.plan.product
        publisher = var.plan.publisher
      }
    } : {}
  )

  sensitive_body = {
    properties = merge(
      var.proximity_placement_group_id != null ? {
        proximityPlacementGroup = {
          id = var.proximity_placement_group_id
        }
      } : {},
      var.sku_name != null ? {
        virtualMachineProfile = merge(
          var.data_base64 != null ? {
            userData = var.data_base64
          } : {},
          local.normalized_license_type != null ? {
            licenseType = local.normalized_license_type
          } : {},
          var.os_profile != null ? {
            osProfile = merge(
              var.os_profile_custom_data != null ? {
                customData = var.os_profile_custom_data
              } : {},
              var.os_profile.linux_configuration != null && var.os_profile_linux_configuration_admin_password != null ? {
                adminPassword = var.os_profile_linux_configuration_admin_password
              } : {},
              var.os_profile.windows_configuration != null && var.os_profile_windows_configuration_admin_password != null ? {
                adminPassword = var.os_profile_windows_configuration_admin_password
              } : {},
              var.os_profile.windows_configuration != null ? {
                windowsConfiguration = merge(
                  var.os_profile.windows_configuration.additional_unattend_content != null && length(local.additional_unattend_content_map) > 0 ? {
                    additionalUnattendContent = [
                      for idx, content in var.os_profile.windows_configuration.additional_unattend_content : {
                        content = local.additional_unattend_content_map[idx]
                      }
                    ]
                  } : {}
                )
              } : {}
            )
          } : {},
          var.extension != null && length(local.extension_protected_settings_map) > 0 ? {
            extensionProfile = {
              extensions = [
                for ext in var.extension : {
                  name = ext.name
                  properties = lookup(local.extension_protected_settings_map, ext.name, null) != null ? {
                    protectedSettings = local.extension_protected_settings_map[ext.name]
                  } : {}
                }
              ]
            }
          } : {},
          var.network_interface != null || var.sku_name != null ? {
            networkProfile = {
              networkApiVersion = local.new_network_api_version
            }
          } : {}
        )
      } : {}
    )
  }

  sensitive_body_version = {
    "properties.proximityPlacementGroup.id"                                                           = "null"
    "properties.virtualMachineProfile.osProfile.customData"                                           = try(tostring(var.os_profile_custom_data_version), "null")
    "properties.virtualMachineProfile.osProfile.adminPassword"                                        = var.os_profile != null && var.os_profile.linux_configuration != null ? try(tostring(var.os_profile_linux_configuration_admin_password_version), "null") : var.os_profile != null && var.os_profile.windows_configuration != null ? try(tostring(var.os_profile_windows_configuration_admin_password_version), "null") : "null"
    "properties.virtualMachineProfile.userData"                                                       = try(tostring(var.user_data_base64_version), "null")
    "properties.virtualMachineProfile.licenseType"                                                    = "null"
    "properties.virtualMachineProfile.networkProfile.networkApiVersion"                               = "null"
    "properties.virtualMachineProfile.extensionProfile.protectedSettings"                             = try(tostring(var.extension_protected_settings_version), "null")
    "properties.virtualMachineProfile.osProfile.windowsConfiguration.additionalUnattendContent"       = try(tostring(var.os_profile_windows_configuration_additional_unattend_content_content_version), "null")
  }

  retry = {
    error_message_regex = [
      "retryable",
      "RetryableError",
      "try later",
      "try again later",
      "please retry",
    ]
  }

  post_creation_updates = [
    {
      azapi_header = {
        type      = "Microsoft.Compute/virtualMachineScaleSets@2024-11-01"
        name      = var.name
        parent_id = var.resource_group_id
      }
      body = {
        properties = merge(
          var.proximity_placement_group_id != null ? {
            proximityPlacementGroup = {
              id = var.proximity_placement_group_id
            }
          } : {},
          {
            virtualMachineProfile = merge(
              local.normalized_license_type != null ? {
                licenseType = local.normalized_license_type
              } : {},
              var.network_interface != null || var.sku_name != null ? {
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
  ]

  locks = []
}
