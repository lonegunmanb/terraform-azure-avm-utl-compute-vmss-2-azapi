data "azapi_resource" "existing" {
  type                   = "Microsoft.Compute/virtualMachineScaleSets@2024-11-01"
  name                   = var.orchestrated_virtual_machine_scale_set_name
  parent_id              = var.orchestrated_virtual_machine_scale_set_resource_group_id
  response_export_values = ["*"]
}

locals {
  azapi_header = {
    type      = "Microsoft.Compute/virtualMachineScaleSets@2024-11-01"
    name      = var.orchestrated_virtual_machine_scale_set_name
    location  = var.orchestrated_virtual_machine_scale_set_location
    parent_id = var.orchestrated_virtual_machine_scale_set_resource_group_id
  }

  existing_zones = try(
    data.azapi_resource.existing.output.zones != null ? toset(data.azapi_resource.existing.output.zones) : toset([]),
    toset([])
  )
  new_zones = var.orchestrated_virtual_machine_scale_set_zones != null ? var.orchestrated_virtual_machine_scale_set_zones : toset([])

  zones_force_new_trigger = anytrue([
    for zone in local.existing_zones : !contains(local.new_zones, zone)
  ])

  existing_single_placement_group = try(
    data.azapi_resource.existing.output.properties.singlePlacementGroup,
    null
  )
  new_single_placement_group = var.orchestrated_virtual_machine_scale_set_single_placement_group

  single_placement_group_force_new_trigger = (
    local.existing_single_placement_group == false &&
    local.new_single_placement_group == true
  )

  replace_triggers_external_values = {
    location                      = { value = var.orchestrated_virtual_machine_scale_set_location }
    platform_fault_domain_count   = { value = var.orchestrated_virtual_machine_scale_set_platform_fault_domain_count }
    zone_balance                  = { value = var.orchestrated_virtual_machine_scale_set_zone_balance }
    zones                         = { value = local.zones_force_new_trigger }
    single_placement_group        = { value = local.single_placement_group_force_new_trigger }
    capacity_reservation_group_id = { value = var.orchestrated_virtual_machine_scale_set_capacity_reservation_group_id }
    eviction_policy               = { value = var.orchestrated_virtual_machine_scale_set_eviction_policy }
    extension_operations_enabled  = { value = var.orchestrated_virtual_machine_scale_set_extension_operations_enabled }
    priority                      = { value = var.orchestrated_virtual_machine_scale_set_priority }
    proximity_placement_group_id  = { value = var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id }
    network_interface_name        = { value = var.orchestrated_virtual_machine_scale_set_network_interface != null ? jsonencode([for nic in var.orchestrated_virtual_machine_scale_set_network_interface : nic.name]) : "" }
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
        var.orchestrated_virtual_machine_scale_set_single_placement_group != null ? {
          singlePlacementGroup = var.orchestrated_virtual_machine_scale_set_single_placement_group
        } : {},
        var.orchestrated_virtual_machine_scale_set_zone_balance != null ? {
          zoneBalance = var.orchestrated_virtual_machine_scale_set_zone_balance
        } : {},
        var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id != null ? {
          proximityPlacementGroup = {
            id = var.orchestrated_virtual_machine_scale_set_proximity_placement_group_id
          }
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
            var.orchestrated_virtual_machine_scale_set_license_type != null && var.orchestrated_virtual_machine_scale_set_license_type != "None" ? {
              licenseType = var.orchestrated_virtual_machine_scale_set_license_type
            } : {},
            var.orchestrated_virtual_machine_scale_set_network_interface != null ? {
              networkProfile = merge(
                var.orchestrated_virtual_machine_scale_set_network_interface != null ? {
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
                          # enableAcceleratedNetworking = ... # Task #65
                          # enableIPForwarding = ... # Task #66
                          # networkSecurityGroup = { # Task #67
                          #   id = ... # Task #67
                          # }
                          # primary = ... # Task #68
                          ipConfigurations = [
                            # for ip_config in nic.ip_configuration : { # Task #69-86
                            #   name = ... # Task #70
                            #   properties = { # Task #71-86
                            #     applicationGatewayBackendAddressPools = ... # Task #71
                            #     applicationSecurityGroups = ... # Task #72
                            #     loadBalancerBackendAddressPools = ... # Task #73
                            #     primary = ... # Task #74
                            #     subnet = { id = ... } # Task #75
                            #     privateIPAddressVersion = ... # Task #76
                            #     publicIPAddressConfiguration = { # Task #77-86
                            #       name = ... # Task #78
                            #       properties = { # Task #79-83
                            #         domainNameLabel = ... # Task #79
                            #         idleTimeoutInMinutes = ... # Task #80
                            #         publicIPPrefix = { id = ... } # Task #81
                            #       }
                            #       sku = { name = ... } # Task #82
                            #       publicIPAddressVersion = ... # Task #83
                            #       ipTags = [ # Task #84-86
                            #         { tag = ..., ipTagType = ... } # Task #85, #86
                            #       ]
                            #     }
                            #   }
                            # }
                          ]
                        }
                      )
                    }
                  ]
                } : {}
              )
            } : {},
            var.orchestrated_virtual_machine_scale_set_os_profile != null ? {
              osProfile = merge(
                {
                  allowExtensionOperations = var.orchestrated_virtual_machine_scale_set_extension_operations_enabled
                },
                var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data != null ? {
                  customData = var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data
                } : {},
                var.orchestrated_virtual_machine_scale_set_os_profile.linux_configuration != null ? {
                  linuxConfiguration = {
                    # adminUsername = ... # Task #99
                    # adminPassword = ... # Task #100
                    # computerNamePrefix = ... # Task #101
                    # disablePasswordAuthentication = ... # Task #102
                    # provisionVMAgent = ... # Task #105
                    # patchSettings = { # Task #103, #104
                    #   assessmentMode = ... # Task #103
                    #   patchMode = ... # Task #104
                    # }
                    # ssh = { # Task #106-108
                    #   publicKeys = ... # Task #106-108
                    # }
                    # secrets = ... # Task #109-112
                  }
                } : {},
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
            var.orchestrated_virtual_machine_scale_set_extensions_time_budget != null ? {
              extensionProfile = {
                extensionsTimeBudget = var.orchestrated_virtual_machine_scale_set_extensions_time_budget
              }
            } : {}
          )
        } : {}
      )
    },
    var.orchestrated_virtual_machine_scale_set_zones != null ? {
      zones = tolist(var.orchestrated_virtual_machine_scale_set_zones)
    } : {},
    var.orchestrated_virtual_machine_scale_set_sku_name != null ? {
      sku = {
        name     = var.orchestrated_virtual_machine_scale_set_sku_name
        capacity = var.orchestrated_virtual_machine_scale_set_instances
        tier     = var.orchestrated_virtual_machine_scale_set_sku_name != "Mix" ? "Standard" : null
      }
    } : {}
  )

  sensitive_body = {
    properties = {}
  }

  sensitive_body_version = {
    "properties.virtualMachineProfile.osProfile.customData" = var.migrate_orchestrated_virtual_machine_scale_set_os_profile_custom_data_version
  }

  post_creation_updates = compact([])

  locks = []
}
