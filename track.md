# Migration Plan: azurerm_orchestrated_virtual_machine_scale_set to azapi_resource

## Resource Type Identification

**AzAPI Resource Type:** `Microsoft.Compute/virtualMachineScaleSets@2024-11-01`

### Evidence from Source Code

From the azurerm provider source code (`resourceOrchestratedVirtualMachineScaleSetCreate` function):

```go
import (
    "github.com/hashicorp/go-azure-sdk/resource-manager/compute/2024-11-01/virtualmachinescalesets"
)

func resourceOrchestratedVirtualMachineScaleSetCreate(d *pluginsdk.ResourceData, meta interface{}) error {
    client := meta.(*clients.Client).Compute.VirtualMachineScaleSetsClient
    // ...
    id := virtualmachinescalesets.NewVirtualMachineScaleSetID(subscriptionId, d.Get("resource_group_name").(string), d.Get("name").(string))
    // ...
    props := virtualmachinescalesets.VirtualMachineScaleSet{
        Location: location.Normalize(d.Get("location").(string)),
        Properties: &virtualmachinescalesets.VirtualMachineScaleSetProperties{
            OrchestrationMode: pointer.To(virtualmachinescalesets.OrchestrationModeFlexible),
            // ...
        },
    }
    // ...
    if err := client.CreateOrUpdateThenPoll(ctx, id, props, virtualmachinescalesets.DefaultCreateOrUpdateOperationOptions()); err != nil {
        return fmt.Errorf("creating Orchestrated %s: %w", id, err)
    }
}
```

**Proof:**
1. The import path shows API version `2024-11-01`
2. The resource type is `virtualMachineScaleSets` under `Microsoft.Compute`
3. The OrchestrationMode is hardcoded to `Flexible` for orchestrated VMSS
4. The full Azure resource type is: `Microsoft.Compute/virtualMachineScaleSets@2024-11-01`

## Planning Task List

| No. | Path | Type | Required | Status | Proof Doc Markdown Link |
|-----|------|------|----------|--------|-----------|
| 1 | name | Argument | Yes | ✅ Completed | [1.name.md](1.name.md) |
| 2 | resource_group_name | Argument | Yes | ✅ Completed | [2.resource_group_name.md](2.resource_group_name.md) |
| 3 | location | Argument | Yes | ✅ Completed | [3.location.md](3.location.md) |
| 4 | platform_fault_domain_count | Argument | Yes | ✅ Completed | [4.platform_fault_domain_count.md](4.platform_fault_domain_count.md) |
| 5 | capacity_reservation_group_id | Argument | No | ✅ Completed | [5.capacity_reservation_group_id.md](5.capacity_reservation_group_id.md) |
| 6 | encryption_at_host_enabled | Argument | No | ✅ Completed | [6.encryption_at_host_enabled.md](6.encryption_at_host_enabled.md) |
| 7 | eviction_policy | Argument | No | ✅ Completed | [7.eviction_policy.md](7.eviction_policy.md) |
| 8 | extension_operations_enabled | Argument | No | ✅ Completed | [8.extension_operations_enabled.md](8.extension_operations_enabled.md) |
| 9 | extensions_time_budget | Argument | No | ✅ Completed | [9.extensions_time_budget.md](9.extensions_time_budget.md) |
| 10 | instances | Argument | No | ✅ Completed | [10.instances.md](10.instances.md) |
| 11 | license_type | Argument | No | ✅ Completed | [11.license_type.md](11.license_type.md) |
| 12 | max_bid_price | Argument | No | ✅ Completed | [12.max_bid_price.md](12.max_bid_price.md) |
| 13 | network_api_version | Argument | No | Pending for check | [13.network_api_version.md](13.network_api_version.md) |
| 14 | priority | Argument | No | ✅ Completed | [14.priority.md](14.priority.md) |
| 15 | proximity_placement_group_id | Argument | No | ✅ Completed | [15.proximity_placement_group_id.md](15.proximity_placement_group_id.md) |
| 16 | single_placement_group | Argument | No | ✅ Completed | [16.single_placement_group.md](16.single_placement_group.md) |
| 17 | sku_name | Argument | No | ✅ Completed | [17.sku_name.md](17.sku_name.md) |
| 18 | source_image_id | Argument | No | ✅ Completed | [18.source_image_id.md](18.source_image_id.md) |
| 19 | tags | Argument | No | ✅ Completed | [19.tags.md](19.tags.md) |
| 20 | upgrade_mode | Argument | No | ✅ Completed | [20.upgrade_mode.md](20.upgrade_mode.md) |
| 21 | user_data_base64 | Argument | No | ✅ Completed | [21.user_data_base64.md](21.user_data_base64.md) |
| 22 | zone_balance | Argument | No | ✅ Completed | [22.zone_balance.md](22.zone_balance.md) |
| 23 | zones | Argument | No | ✅ Completed | [23.zones.md](23.zones.md) |
| 24 | __check_root_hidden_fields__ | HiddenFieldsCheck | Yes | ✅ Completed | [24.__check_root_hidden_fields__.md](24.__check_root_hidden_fields__.md) |
| 25 | additional_capabilities | Block | No | ✅ Completed | [25.additional_capabilities.md](25.additional_capabilities.md) |
| 26 | additional_capabilities.ultra_ssd_enabled | Argument | No | ✅ Completed | [26.additional_capabilities.ultra_ssd_enabled.md](26.additional_capabilities.ultra_ssd_enabled.md) |
| 27 | automatic_instance_repair | Block | No | ✅ Completed | [27.automatic_instance_repair.md](27.automatic_instance_repair.md) |
| 28 | automatic_instance_repair.enabled | Argument | Yes | ✅ Completed | [28.automatic_instance_repair.enabled.md](28.automatic_instance_repair.enabled.md) |
| 29 | automatic_instance_repair.action | Argument | No | ✅ Completed | [29.automatic_instance_repair.action.md](29.automatic_instance_repair.action.md) |
| 30 | automatic_instance_repair.grace_period | Argument | No | ✅ Completed | [30.automatic_instance_repair.grace_period.md](30.automatic_instance_repair.grace_period.md) |
| 31 | boot_diagnostics | Block | No | ✅ Completed | [31.boot_diagnostics.md](31.boot_diagnostics.md) |
| 32 | boot_diagnostics.storage_account_uri | Argument | No | ✅ Completed | [32.boot_diagnostics.storage_account_uri.md](32.boot_diagnostics.storage_account_uri.md) |
| 33 | data_disk | Block | No | ✅ Completed | [33.data_disk.md](33.data_disk.md) |
| 34 | data_disk.caching | Argument | Yes | ✅ Completed | [34.data_disk.caching.md](34.data_disk.caching.md) |
| 35 | data_disk.storage_account_type | Argument | Yes | ✅ Completed | [35.data_disk.storage_account_type.md](35.data_disk.storage_account_type.md) |
| 36 | data_disk.create_option | Argument | No | ✅ Completed | [36.data_disk.create_option.md](36.data_disk.create_option.md) |
| 37 | data_disk.disk_encryption_set_id | Argument | No | ✅ Completed | [37.data_disk.disk_encryption_set_id.md](37.data_disk.disk_encryption_set_id.md) |
| 38 | data_disk.disk_size_gb | Argument | No | ✅ Completed | [38.data_disk.disk_size_gb.md](38.data_disk.disk_size_gb.md) |
| 39 | data_disk.lun | Argument | Yes | ✅ Completed | [39.data_disk.lun.md](39.data_disk.lun.md) |
| 40 | data_disk.ultra_ssd_disk_iops_read_write | Argument | No | ✅ Completed | [40.data_disk.ultra_ssd_disk_iops_read_write.md](40.data_disk.ultra_ssd_disk_iops_read_write.md) |
| 41 | data_disk.ultra_ssd_disk_mbps_read_write | Argument | No | ✅ Completed | [41.data_disk.ultra_ssd_disk_mbps_read_write.md](41.data_disk.ultra_ssd_disk_mbps_read_write.md) |
| 42 | data_disk.write_accelerator_enabled | Argument | No | ✅ Completed | [42.data_disk.write_accelerator_enabled.md](42.data_disk.write_accelerator_enabled.md) |
| 43 | extension | Block | No | ✅ Completed | [43.extension.md](43.extension.md) |
| 44 | extension.name | Argument | Yes | ✅ Completed | [44.extension.name.md](44.extension.name.md) |
| 45 | extension.publisher | Argument | Yes | ✅ Completed | [45.extension.publisher.md](45.extension.publisher.md) |
| 46 | extension.type | Argument | Yes | ✅ Completed | [46.extension.type.md](46.extension.type.md) |
| 47 | extension.type_handler_version | Argument | Yes | ✅ Completed | [47.extension.type_handler_version.md](47.extension.type_handler_version.md) |
| 48 | extension.auto_upgrade_minor_version_enabled | Argument | No | ✅ Completed | [48.extension.auto_upgrade_minor_version_enabled.md](48.extension.auto_upgrade_minor_version_enabled.md) |
| 49 | extension.extensions_to_provision_after_vm_creation | Argument | No | ✅ Completed | [49.extension.extensions_to_provision_after_vm_creation.md](49.extension.extensions_to_provision_after_vm_creation.md) |
| 50 | extension.failure_suppression_enabled | Argument | No | ✅ Completed | [50.extension.failure_suppression_enabled.md](50.extension.failure_suppression_enabled.md) |
| 51 | extension.force_extension_execution_on_change | Argument | No | ✅ Completed | [51.extension.force_extension_execution_on_change.md](51.extension.force_extension_execution_on_change.md) |
| 52 | extension.protected_settings | Argument | No | ✅ Completed | [52.extension.protected_settings.md](52.extension.protected_settings.md) |
| 53 | extension.settings | Argument | No | ✅ Completed | [53.extension.settings.md](53.extension.settings.md) |
| 54 | extension.protected_settings_from_key_vault | Block | No | ✅ Completed | [54.extension.protected_settings_from_key_vault.md](54.extension.protected_settings_from_key_vault.md) |
| 55 | extension.protected_settings_from_key_vault.secret_url | Argument | Yes | ✅ Completed | [55.extension.protected_settings_from_key_vault.secret_url.md](55.extension.protected_settings_from_key_vault.secret_url.md) |
| 56 | extension.protected_settings_from_key_vault.source_vault_id | Argument | Yes | ✅ Completed | [56.extension.protected_settings_from_key_vault.source_vault_id.md](56.extension.protected_settings_from_key_vault.source_vault_id.md) |
| 57 | identity | Block | No | ✅ Completed | [57.identity.md](57.identity.md) |
| 58 | identity.type | Argument | Yes | ✅ Completed | [58.identity.type.md](58.identity.type.md) |
| 59 | identity.identity_ids | Argument | No | ✅ Completed | [59.identity.identity_ids.md](59.identity.identity_ids.md) |
| 60 | network_interface | Block | No | ✅ Completed | [60.network_interface.md](60.network_interface.md) |
| 61 | network_interface.name | Argument | Yes | ✅ Completed | [61.network_interface.name.md](61.network_interface.name.md) |
| 62 | network_interface.auxiliary_mode | Argument | No | ✅ Completed | [62.network_interface.auxiliary_mode.md](62.network_interface.auxiliary_mode.md) |
| 63 | network_interface.auxiliary_sku | Argument | No | ✅ Completed | [63.network_interface.auxiliary_sku.md](63.network_interface.auxiliary_sku.md) |
| 64 | network_interface.dns_servers | Argument | No | ✅ Completed | [64.network_interface.dns_servers.md](64.network_interface.dns_servers.md) |
| 65 | network_interface.enable_accelerated_networking | Argument | No | ✅ Completed | [65.network_interface.enable_accelerated_networking.md](65.network_interface.enable_accelerated_networking.md) |
| 66 | network_interface.enable_ip_forwarding | Argument | No | ✅ Completed | [66.network_interface.enable_ip_forwarding.md](66.network_interface.enable_ip_forwarding.md) |
| 67 | network_interface.network_security_group_id | Argument | No | ✅ Completed | [67.network_interface.network_security_group_id.md](67.network_interface.network_security_group_id.md) |
| 68 | network_interface.primary | Argument | No | ✅ Completed | [68.network_interface.primary.md](68.network_interface.primary.md) |
| 69 | network_interface.ip_configuration | Block | Yes | ✅ Completed | [69.network_interface.ip_configuration.md](69.network_interface.ip_configuration.md) |
| 70 | network_interface.ip_configuration.name | Argument | Yes | ✅ Completed | [70.network_interface.ip_configuration.name.md](70.network_interface.ip_configuration.name.md) |
| 71 | network_interface.ip_configuration.application_gateway_backend_address_pool_ids | Argument | No | ✅ Completed | [71.network_interface.ip_configuration.application_gateway_backend_address_pool_ids.md](71.network_interface.ip_configuration.application_gateway_backend_address_pool_ids.md) |
| 72 | network_interface.ip_configuration.application_security_group_ids | Argument | No | ✅ Completed | [72.network_interface.ip_configuration.application_security_group_ids.md](72.network_interface.ip_configuration.application_security_group_ids.md) |
| 73 | network_interface.ip_configuration.load_balancer_backend_address_pool_ids | Argument | No | ✅ Completed | [73.network_interface.ip_configuration.load_balancer_backend_address_pool_ids.md](73.network_interface.ip_configuration.load_balancer_backend_address_pool_ids.md) |
| 74 | network_interface.ip_configuration.primary | Argument | No | ✅ Completed | [74.network_interface.ip_configuration.primary.md](74.network_interface.ip_configuration.primary.md) |
| 75 | network_interface.ip_configuration.subnet_id | Argument | No | ✅ Completed | [75.network_interface.ip_configuration.subnet_id.md](75.network_interface.ip_configuration.subnet_id.md) |
| 76 | network_interface.ip_configuration.version | Argument | No | ✅ Completed | [76.network_interface.ip_configuration.version.md](76.network_interface.ip_configuration.version.md) |
| 77 | network_interface.ip_configuration.public_ip_address | Block | No | ✅ Completed | [77.network_interface.ip_configuration.public_ip_address.md](77.network_interface.ip_configuration.public_ip_address.md) |
| 78 | network_interface.ip_configuration.public_ip_address.name | Argument | Yes | ✅ Completed | [78.network_interface.ip_configuration.public_ip_address.name.md](78.network_interface.ip_configuration.public_ip_address.name.md) |
| 79 | network_interface.ip_configuration.public_ip_address.domain_name_label | Argument | No | ✅ Completed | [79.network_interface.ip_configuration.public_ip_address.domain_name_label.md](79.network_interface.ip_configuration.public_ip_address.domain_name_label.md) |
| 80 | network_interface.ip_configuration.public_ip_address.idle_timeout_in_minutes | Argument | No | ✅ Completed | [80.network_interface.ip_configuration.public_ip_address.idle_timeout_in_minutes.md](80.network_interface.ip_configuration.public_ip_address.idle_timeout_in_minutes.md) |
| 81 | network_interface.ip_configuration.public_ip_address.public_ip_prefix_id | Argument | No | ✅ Completed | [81.network_interface.ip_configuration.public_ip_address.public_ip_prefix_id.md](81.network_interface.ip_configuration.public_ip_address.public_ip_prefix_id.md) |
| 82 | network_interface.ip_configuration.public_ip_address.sku_name | Argument | No | ✅ Completed | [82.network_interface.ip_configuration.public_ip_address.sku_name.md](82.network_interface.ip_configuration.public_ip_address.sku_name.md) |
| 83 | network_interface.ip_configuration.public_ip_address.version | Argument | No | ✅ Completed | [83.network_interface.ip_configuration.public_ip_address.version.md](83.network_interface.ip_configuration.public_ip_address.version.md) |
| 84 | network_interface.ip_configuration.public_ip_address.ip_tag | Block | No | ✅ Completed | [84.network_interface.ip_configuration.public_ip_address.ip_tag.md](84.network_interface.ip_configuration.public_ip_address.ip_tag.md) |
| 85 | network_interface.ip_configuration.public_ip_address.ip_tag.tag | Argument | Yes | ✅ Completed | [85.network_interface.ip_configuration.public_ip_address.ip_tag.tag.md](85.network_interface.ip_configuration.public_ip_address.ip_tag.tag.md) |
| 86 | network_interface.ip_configuration.public_ip_address.ip_tag.type | Argument | Yes | ✅ Completed | [86.network_interface.ip_configuration.public_ip_address.ip_tag.type.md](86.network_interface.ip_configuration.public_ip_address.ip_tag.type.md) |
| 87 | os_disk | Block | No | ✅ Completed | [87.os_disk.md](87.os_disk.md) |
| 88 | os_disk.caching | Argument | Yes | ✅ Completed | [88.os_disk.caching.md](88.os_disk.caching.md) |
| 89 | os_disk.storage_account_type | Argument | Yes | ✅ Completed | [89.os_disk.storage_account_type.md](89.os_disk.storage_account_type.md) |
| 90 | os_disk.disk_encryption_set_id | Argument | No | ✅ Completed | [90.os_disk.disk_encryption_set_id.md](90.os_disk.disk_encryption_set_id.md) |
| 91 | os_disk.disk_size_gb | Argument | No | ✅ Completed | [91.os_disk.disk_size_gb.md](91.os_disk.disk_size_gb.md) |
| 92 | os_disk.write_accelerator_enabled | Argument | No | ✅ Completed | [92.os_disk.write_accelerator_enabled.md](92.os_disk.write_accelerator_enabled.md) |
| 93 | os_disk.diff_disk_settings | Block | No | ✅ Completed | [93.os_disk.diff_disk_settings.md](93.os_disk.diff_disk_settings.md) |
| 94 | os_disk.diff_disk_settings.option | Argument | Yes | ✅ Completed | [94.os_disk.diff_disk_settings.option.md](94.os_disk.diff_disk_settings.option.md) |
| 95 | os_disk.diff_disk_settings.placement | Argument | No | ✅ Completed | [95.os_disk.diff_disk_settings.placement.md](95.os_disk.diff_disk_settings.placement.md) |
| 96 | os_profile | Block | No | ✅ Completed | [96.os_profile.md](96.os_profile.md) |
| 97 | os_profile.custom_data | Argument | No | ✅ Completed | [97.os_profile.custom_data.md](97.os_profile.custom_data.md) |
| 98 | os_profile.linux_configuration | Block | No | ✅ Completed | [98.linux_configuration.md](98.linux_configuration.md) |
| 99 | os_profile.linux_configuration.admin_username | Argument | Yes | ✅ Completed | [99.os_profile.linux_configuration.admin_username.md](99.os_profile.linux_configuration.admin_username.md) |
| 100 | os_profile.linux_configuration.admin_password | Argument | No | ✅ Completed | [100.os_profile.linux_configuration.admin_password.md](100.os_profile.linux_configuration.admin_password.md) |
| 101 | os_profile.linux_configuration.computer_name_prefix | Argument | No | ✅ Completed | [101.os_profile.linux_configuration.computer_name_prefix.md](101.os_profile.linux_configuration.computer_name_prefix.md) |
| 102 | os_profile.linux_configuration.disable_password_authentication | Argument | No | ✅ Completed | [102.os_profile.linux_configuration.disable_password_authentication.md](102.os_profile.linux_configuration.disable_password_authentication.md) |
| 103 | os_profile.linux_configuration.patch_assessment_mode | Argument | No | ✅ Completed | [103.os_profile.linux_configuration.patch_assessment_mode.md](103.os_profile.linux_configuration.patch_assessment_mode.md) |
| 104 | os_profile.linux_configuration.patch_mode | Argument | No | ✅ Completed | [104.os_profile.linux_configuration.patch_mode.md](104.os_profile.linux_configuration.patch_mode.md) |
| 105 | os_profile.linux_configuration.provision_vm_agent | Argument | No | ✅ Completed | [105.os_profile.linux_configuration.provision_vm_agent.md](105.os_profile.linux_configuration.provision_vm_agent.md) |
| 106 | os_profile.linux_configuration.admin_ssh_key | Block | No | ✅ Completed | [106.os_profile.linux_configuration.admin_ssh_key.md](106.os_profile.linux_configuration.admin_ssh_key.md) |
| 107 | os_profile.linux_configuration.admin_ssh_key.public_key | Argument | Yes | ✅ Completed | [107.os_profile.linux_configuration.admin_ssh_key.public_key.md](107.os_profile.linux_configuration.admin_ssh_key.public_key.md) |
| 108 | os_profile.linux_configuration.admin_ssh_key.username | Argument | Yes | ✅ Completed | [108.os_profile.linux_configuration.admin_ssh_key.username.md](108.os_profile.linux_configuration.admin_ssh_key.username.md) |
| 109 | os_profile.linux_configuration.secret | Block | No | ✅ Completed | [109.os_profile.linux_configuration.secret.md](109.os_profile.linux_configuration.secret.md) |
| 110 | os_profile.linux_configuration.secret.key_vault_id | Argument | Yes | ✅ Completed | [110.os_profile.linux_configuration.secret.key_vault_id.md](110.os_profile.linux_configuration.secret.key_vault_id.md) |
| 111 | os_profile.linux_configuration.secret.certificate | Block | Yes | ✅ Completed | [111.os_profile.linux_configuration.secret.certificate.md](111.os_profile.linux_configuration.secret.certificate.md) |
| 112 | os_profile.linux_configuration.secret.certificate.url | Argument | Yes | ✅ Completed | [112.os_profile.linux_configuration.secret.certificate.url.md](112.os_profile.linux_configuration.secret.certificate.url.md) |
| 113 | os_profile.windows_configuration | Block | No | ✅ Completed | [113.os_profile.windows_configuration.md](113.os_profile.windows_configuration.md) |
| 114 | os_profile.windows_configuration.admin_password | Argument | Yes | ✅ Completed | [114.os_profile.windows_configuration.admin_password.md](114.os_profile.windows_configuration.admin_password.md) |
| 115 | os_profile.windows_configuration.admin_username | Argument | Yes | ✅ Completed | [115.os_profile.windows_configuration.admin_username.md](115.os_profile.windows_configuration.admin_username.md) |
| 116 | os_profile.windows_configuration.computer_name_prefix | Argument | No | ✅ Completed | [116.os_profile.windows_configuration.computer_name_prefix.md](116.os_profile.windows_configuration.computer_name_prefix.md) |
| 117 | os_profile.windows_configuration.enable_automatic_updates | Argument | No | ✅ Completed | [117.os_profile.windows_configuration.enable_automatic_updates.md](117.os_profile.windows_configuration.enable_automatic_updates.md) |
| 118 | os_profile.windows_configuration.hotpatching_enabled | Argument | No | ✅ Completed | [118.os_profile.windows_configuration.hotpatching_enabled.md](118.os_profile.windows_configuration.hotpatching_enabled.md) |
| 119 | os_profile.windows_configuration.patch_assessment_mode | Argument | No | ✅ Completed | [119.os_profile.windows_configuration.patch_assessment_mode.md](119.os_profile.windows_configuration.patch_assessment_mode.md) |
| 120 | os_profile.windows_configuration.patch_mode | Argument | No | ✅ Completed | [120.os_profile.windows_configuration.patch_mode.md](120.os_profile.windows_configuration.patch_mode.md) |
| 121 | os_profile.windows_configuration.provision_vm_agent | Argument | No | ✅ Completed | [121.os_profile.windows_configuration.provision_vm_agent.md](121.os_profile.windows_configuration.provision_vm_agent.md) |
| 122 | os_profile.windows_configuration.timezone | Argument | No | ✅ Completed | [122.os_profile.windows_configuration.timezone.md](122.os_profile.windows_configuration.timezone.md) |
| 123 | os_profile.windows_configuration.additional_unattend_content | Block | No | ✅ Completed | [123.os_profile.windows_configuration.additional_unattend_content.md](123.os_profile.windows_configuration.additional_unattend_content.md) |
| 124 | os_profile.windows_configuration.additional_unattend_content.content | Argument | Yes | ✅ Completed | [124.os_profile.windows_configuration.additional_unattend_content.content.md](124.os_profile.windows_configuration.additional_unattend_content.content.md) |
| 125 | os_profile.windows_configuration.additional_unattend_content.setting | Argument | Yes | ✅ Completed | [125.os_profile.windows_configuration.additional_unattend_content.setting.md](125.os_profile.windows_configuration.additional_unattend_content.setting.md) |
| 126 | os_profile.windows_configuration.secret | Block | No | ✅ Completed | [126.os_profile.windows_configuration.secret.md](126.os_profile.windows_configuration.secret.md) |
| 127 | os_profile.windows_configuration.secret.key_vault_id | Argument | Yes | ✅ Completed | [127.os_profile.windows_configuration.secret.key_vault_id.md](127.os_profile.windows_configuration.secret.key_vault_id.md) |
| 128 | os_profile.windows_configuration.secret.certificate | Block | Yes | ✅ Completed | [128.os_profile.windows_configuration.secret.certificate.md](128.os_profile.windows_configuration.secret.certificate.md) |
| 129 | os_profile.windows_configuration.secret.certificate.store | Argument | Yes | ✅ Completed | [129.os_profile.windows_configuration.secret.certificate.store.md](129.os_profile.windows_configuration.secret.certificate.store.md) |
| 130 | os_profile.windows_configuration.secret.certificate.url | Argument | Yes | ✅ Completed | [130.os_profile.windows_configuration.secret.certificate.url.md](130.os_profile.windows_configuration.secret.certificate.url.md) |
| 131 | os_profile.windows_configuration.winrm_listener | Block | No | ✅ Completed | [131.os_profile.windows_configuration.winrm_listener.md](131.os_profile.windows_configuration.winrm_listener.md) |
| 132 | os_profile.windows_configuration.winrm_listener.protocol | Argument | Yes | ✅ Completed | [132.os_profile.windows_configuration.winrm_listener.protocol.md](132.os_profile.windows_configuration.winrm_listener.protocol.md) |
| 133 | os_profile.windows_configuration.winrm_listener.certificate_url | Argument | No | ✅ Completed | [133.os_profile.windows_configuration.winrm_listener.certificate_url.md](133.os_profile.windows_configuration.winrm_listener.certificate_url.md) |
| 134 | plan | Block | No | ✅ Completed | [134.plan.md](134.plan.md) |
| 135 | plan.name | Argument | Yes | ✅ Completed | [135.plan.name.md](135.plan.name.md) |
| 136 | plan.product | Argument | Yes | ✅ Completed | [136.plan.product.md](136.plan.product.md) |
| 137 | plan.publisher | Argument | Yes | ✅ Completed | [137.plan.publisher.md](137.plan.publisher.md) |
| 138 | priority_mix | Block | No | ✅ Completed | [138.priority_mix.md](138.priority_mix.md) |
| 139 | priority_mix.base_regular_count | Argument | No | ✅ Completed | [139.priority_mix.base_regular_count.md](139.priority_mix.base_regular_count.md) |
| 140 | priority_mix.regular_percentage_above_base | Argument | No | ✅ Completed | [140.priority_mix.regular_percentage_above_base.md](140.priority_mix.regular_percentage_above_base.md) |
| 141 | rolling_upgrade_policy | Block | No | ✅ Completed | [141.rolling_upgrade_policy.md](141.rolling_upgrade_policy.md) |
| 142 | rolling_upgrade_policy.max_batch_instance_percent | Argument | Yes | ✅ Completed | [142.rolling_upgrade_policy.max_batch_instance_percent.md](142.rolling_upgrade_policy.max_batch_instance_percent.md) |
| 143 | rolling_upgrade_policy.max_unhealthy_instance_percent | Argument | Yes | ✅ Completed | [143.rolling_upgrade_policy.max_unhealthy_instance_percent.md](143.rolling_upgrade_policy.max_unhealthy_instance_percent.md) |
| 144 | rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent | Argument | Yes | ✅ Completed | [144.rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent.md](144.rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent.md) |
| 145 | rolling_upgrade_policy.pause_time_between_batches | Argument | Yes | ✅ Completed | [145.rolling_upgrade_policy.pause_time_between_batches.md](145.rolling_upgrade_policy.pause_time_between_batches.md) |
| 146 | rolling_upgrade_policy.cross_zone_upgrades_enabled | Argument | No | ✅ Completed | [146.rolling_upgrade_policy.cross_zone_upgrades_enabled.md](146.rolling_upgrade_policy.cross_zone_upgrades_enabled.md) |
| 147 | rolling_upgrade_policy.maximum_surge_instances_enabled | Argument | No | ✅ Completed | [147.rolling_upgrade_policy.maximum_surge_instances_enabled.md](147.rolling_upgrade_policy.maximum_surge_instances_enabled.md) |
| 148 | rolling_upgrade_policy.prioritize_unhealthy_instances_enabled | Argument | No | ✅ Completed | [148.rolling_upgrade_policy.prioritize_unhealthy_instances_enabled.md](148.rolling_upgrade_policy.prioritize_unhealthy_instances_enabled.md) |
| 149 | sku_profile | Block | No | ✅ Completed | [149.sku_profile.md](149.sku_profile.md) |
| 150 | sku_profile.allocation_strategy | Argument | Yes | ✅ Completed | [150.sku_profile.allocation_strategy.md](150.sku_profile.allocation_strategy.md) |
| 151 | sku_profile.vm_sizes | Argument | Yes | ✅ Completed | [151.sku_profile.vm_sizes.md](151.sku_profile.vm_sizes.md) |
| 152 | source_image_reference | Block | No | ✅ Completed | [152.source_image_reference.md](152.source_image_reference.md) |
| 153 | source_image_reference.offer | Argument | Yes | ✅ Completed | [153.source_image_reference.offer.md](153.source_image_reference.offer.md) |
| 154 | source_image_reference.publisher | Argument | Yes | ✅ Completed | [154.source_image_reference.publisher.md](154.source_image_reference.publisher.md) |
| 155 | source_image_reference.sku | Argument | Yes | ✅ Completed | [155.source_image_reference.sku.md](155.source_image_reference.sku.md) |
| 156 | source_image_reference.version | Argument | Yes | ✅ Completed | [156.source_image_reference.version.md](156.source_image_reference.version.md) |
| 157 | termination_notification | Block | No | ✅ Completed | [157.termination_notification.md](157.termination_notification.md) |
| 158 | termination_notification.enabled | Argument | Yes | ✅ Completed | [158.termination_notification.enabled.md](158.termination_notification.enabled.md) |
| 159 | termination_notification.timeout | Argument | No | ✅ Completed | [159.termination_notification.timeout.md](159.termination_notification.timeout.md) |
| 160 | timeouts | Block | No | ✅ Completed | [160.timeouts.md](160.timeouts.md) |
| 161 | timeouts.create | Argument | No | ✅ Completed | [161.timeouts.create.md](161.timeouts.create.md) |
| 162 | timeouts.delete | Argument | No | ✅ Completed | [162.timeouts.delete.md](162.timeouts.delete.md) |
| 163 | timeouts.read | Argument | No | ✅ Completed | [163.timeouts.read.md](163.timeouts.read.md) |
| 164 | timeouts.update | Argument | No | ✅ Completed | [164.timeouts.update.md](164.timeouts.update.md) |

## Notes

- Total of 164 items to migrate
- The resource uses OrchestrationMode = Flexible
- Many complex nested blocks including network_interface, os_profile, extension, etc.
- Some properties have special validation requirements (e.g., rolling_upgrade_policy only valid when upgrade_mode is Rolling)
- The "Proof Doc Markdown Link" column is intentionally left EMPTY for executor agents to fill in after completion
