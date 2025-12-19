# Test Configuration Functions for azurerm_orchestrated_virtual_machine_scale_set

## Test Cases Summary

**Notes**: 
- Test cases marked with status `invalid` should be skipped during testing unless explicitly commanded by a human to run.
- Test cases with status `test success` can be rerun at any time, as new changes may be imported after a task has been tested.

| case name | file url | status | test status |
| --- | --- | --- |
| basic | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| regression15299 | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| evictionPolicyDelete | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | invalid |
| specializedImage | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| withPPG | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| basicApplicationSecurity | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| basicWindows | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| otherAdditionalUnattendContent | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| basicWindowsNoTimezone | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| linux | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| linuxInstances | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| linuxUpdated | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| linuxCustomDataUpdated | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| bootDiagnostic | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| bootDiagnostic_noStorage | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| linuxEd25119SshKey | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| linuxKeyDataUpdated | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| applicationGatewayTemplate | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | invalid | step 2 failed |
| skuProfile | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| skuProfileUpdate | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | invalid|
| priorityMixPolicy | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | invalid |
| updatePriorityMixPolicy | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | invalid |
| osProfile_empty | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed | test success |
| basicLinux_managedDisk | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | test success |
| basicLinux_managedDisk_withZones | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | invalid |
| loadBalancerTemplateManagedDataDisks | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | test success |
| disksDataDiskStorageAccountType_PremiumLRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | test success |
| disksDataDiskStorageAccountTypePremiumV2LRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | test success |
| disksDataDiskStorageAccountType_PremiumZRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | test success |
| disksDataDiskStorageAccountType_StandardLRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | test success |
| disksDataDiskStorageAccountType_StandardSSDLRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | test success |
| disksDataDiskStorageAccountType_StandardSSDZRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | test success |
| disksDataDiskStorageAccountTypeUltraSSDLRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | test success |
| dataDiskMarketPlaceImage | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_data_test.go | Completed | test success |
| disksOSDiskEphemeral_CacheDisk | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_os_test.go | invalid | step 2 failed |
| disksOSDiskEphemeral_ResourceDisk | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_os_test.go | Completed | test success |
| disksOSDiskStorageAccountType_PremiumLRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_os_test.go | Completed | test success |
| disksOSDiskStorageAccountType_PremiumZRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_os_test.go | Completed | test success |
| disksOSDiskStorageAccountType_StandardLRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_os_test.go | Completed | test success |
| disksOSDiskStorageAccountType_StandardSSDLRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_os_test.go | Completed | test success |
| disksOSDiskStorageAccountType_StandardSSDZRS | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_disk_os_test.go | Completed | test success |
| extensionTemplate | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_extensions_test.go | Completed | test success |
| extensionTemplateUpdated | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_extensions_test.go | Completed | test success |
| multipleExtensionsTemplate | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_extensions_test.go | Completed | test success |
| multipleExtensionsTemplate_provisionMultipleExtensionOnExistingOvmss | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_extensions_test.go | Completed | test success |
| extensionOperationsEnabled | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_extensions_test.go | Completed | test success |
| extensionOperationsDisabled | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_extensions_test.go | Completed | test success |
| extensionFailureSuppression | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_extensions_test.go | Completed | test success |
| extensionFailureSuppressionUpdated | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_extensions_test.go | Completed | test success |
| extensionProtectedSettingsFromKeyVault | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_extensions_test.go | Completed | invalid |
| extensionProtectedSettingsFromKeyVaultUpdated | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_extensions_test.go | Completed | invalid |

---

## Detailed Breakdown

### Basic/Foundation Cases (4 cases):
1. **`r.basic(data)`** - Basic Linux configuration with 2 instances, Standard_D1_v2 SKU
2. **`r.regression15299(data)`** - Regression test for #15299 - tests default computer_name_prefix when not defined
3. **`r.linux(data)`** - Basic Linux with load balancer backend, custom data, SSH key (1 instance)
4. **`r.osProfile_empty(data)`** - Regression test #29748 - empty os_profile block

### OS-Specific Cases (6 cases):
5. **`r.basicWindows(data)`** - Basic Windows configuration with WinRM listener
6. **`r.basicWindowsNoTimezone(data)`** - Windows configuration without timezone specified
7. **`r.otherAdditionalUnattendContent(data)`** - Windows with additional unattend content (FirstLogonCommands)
8. **`r.linuxInstances(data)`** - Linux with 2 instances (regression test for #19155)
9. **`r.linuxEd25119SshKey(data)`** - Linux with Ed25519 SSH key format
10. **`r.linuxKeyDataUpdated(data)`** - Linux with updated RSA SSH key

### Feature-Specific Cases (7 cases):
11. **`r.specializedImage(data)`** - Uses specialized shared image version
12. **`r.withPPG(data)`** - Configuration with proximity placement group
13. **`r.basicApplicationSecurity(data)`** - Configuration with application security group
14. **`r.bootDiagnostic(data)`** - Boot diagnostics with storage account
15. **`r.bootDiagnostic_noStorage(data)`** - Boot diagnostics without storage account URI
16. **`r.applicationGatewayTemplate(data)`** - Configuration with application gateway backend pool
17. **`r.evictionPolicyDelete(data)`** - Spot priority with Delete eviction policy

### Update/Lifecycle Cases (3 cases):
18. **`r.linuxUpdated(data)`** - Updated Linux configuration with tags
19. **`r.linuxCustomDataUpdated(data)`** - Linux with updated custom data
20. **`r.updatePriorityMixPolicy(data)`** - Updated priority mix policy

### Advanced Configuration Cases (3 cases):
21. **`r.skuProfile(data)`** - SKU profile with Mix sku_name and VM sizes (Spot priority, CapacityOptimized)
22. **`r.skuProfileUpdate(data)`** - Updated SKU profile (LowestPrice allocation, different VM sizes)
23. **`r.priorityMixPolicy(data)`** - Priority mix policy with base_regular_count and percentage

### Disk Configuration Cases - Data Disks (11 cases):
24. **`r.basicLinux_managedDisk(data)`** - Basic managed disk configuration
25. **`r.basicLinux_managedDisk_withZones(data)`** - Managed disk with zone 1 specified
26. **`r.loadBalancerTemplateManagedDataDisks(data)`** - With data disk (10GB Standard_LRS)
27. **`r.disksDataDiskStorageAccountType(data, "Premium_LRS")`** - Data disk with Premium_LRS storage
28. **`r.disksDataDiskStorageAccountTypePremiumV2LRS(data)`** - Data disk with PremiumV2_LRS (zonal, westeurope)
29. **`r.disksDataDiskStorageAccountType(data, "Premium_ZRS")`** - Data disk with Premium_ZRS (zone-redundant)
30. **`r.disksDataDiskStorageAccountType(data, "Standard_LRS")`** - Data disk with Standard_LRS
31. **`r.disksDataDiskStorageAccountType(data, "StandardSSD_LRS")`** - Data disk with StandardSSD_LRS
32. **`r.disksDataDiskStorageAccountType(data, "StandardSSD_ZRS")`** - Data disk with StandardSSD_ZRS
33. **`r.disksDataDiskStorageAccountTypeUltraSSDLRS(data)`** - Data disk with UltraSSD_LRS (requires ultra_ssd_enabled, eastus2)
34. **`r.dataDiskMarketPlaceImage(data)`** - Data disk created from marketplace image (900GB from ArcsightLogger)

### Disk Configuration Cases - OS Disk (7 cases):
35. **`r.disksOSDiskEphemeral(data, "CacheDisk")`** - Ephemeral OS disk with CacheDisk placement
36. **`r.disksOSDiskEphemeral(data, "ResourceDisk")`** - Ephemeral OS disk with ResourceDisk placement
37. **`r.disksOSDiskStorageAccountType(data, "Premium_LRS")`** - OS disk with Premium_LRS
38. **`r.disksOSDiskStorageAccountType(data, "Premium_ZRS")`** - OS disk with Premium_ZRS (westeurope)
39. **`r.disksOSDiskStorageAccountType(data, "Standard_LRS")`** - OS disk with Standard_LRS
40. **`r.disksOSDiskStorageAccountType(data, "StandardSSD_LRS")`** - OS disk with StandardSSD_LRS
41. **`r.disksOSDiskStorageAccountType(data, "StandardSSD_ZRS")`** - OS disk with StandardSSD_ZRS (westeurope)
51

**Source Files**:
- Main: `orchestrated_virtual_machine_scale_set_resource_test.go` (23 cases)
- Data Disks: `orchestrated_virtual_machine_scale_set_resource_disk_data_test.go` (11 cases)
- OS Disks: `orchestrated_virtual_machine_scale_set_resource_disk_os_test.go` (7 cases)
- Extensions: `orchestrated_virtual_machine_scale_set_resource_extensions_test.go` (10 cases)

**Notes**:
- Some test functions are used in multiple test scenarios (e.g., `r.linux()` is used as base config in several update tests)
- Extension tests set instances=0 to avoid timeout during VMSS allocation
- PremiumV2_LRS and UltraSSD_LRS require specific regions (westeurope/eastus2) and zonal deployment
- Premium_ZRS and StandardSSD_ZRS require westeurope region
- Priority mix and SKU profile features are preview features with specific region requirements (eastus2)
- Several update test cases validate transitions between states (A → B)
47. **`r.extensionOperationsDisabled(data)`** - With extension_operations_enabled = false
48. **`r.extensionFailureSuppression(data)`** - Extension with failure_suppression_enabled = true
49. **`r.extensionFailureSuppressionUpdated(data)`** - Extension with failure_suppression_enabled = false
50. **`r.extensionProtectedSettingsFromKeyVault(data)`** - Extension protected settings from Key Vault (index 0)
51. **`r.extensionProtectedSettingsFromKeyVaultUpdated(data)`** - Extension protected settings from different Key Vault (index 1)

---

## Excluded Cases

### ❌ Helper/Template Functions (only called by other configs):
- **`r.natgateway_template(data)`** - Template function providing NAT gateway, VNet, subnet infrastructure
  - Used via `%[3]s` injection in many test configs
  - Never used directly in TestStep.Config

### ❌ Error Test Cases (used with ExpectError):
- **`r.requiresImport(data)`** - Tests import error validation
  - Used with `ExpectError: acceptance.RequiresImportError(...)`
- **`r.skuProfileWithoutSkuName(data)`** - Error case: sku_profile without sku_name set to "Mix"
  - Used with `ExpectError: regexp.MustCompile(...)`
- **`r.skuProfileSkuNameIsNotMix(data)`** - Error case: sku_profile with sku_name != "Mix"
  - Used with `ExpectError: regexp.MustCompile(...)`
- **`r.skuProfileNotExist(data)`** - Error case: sku_name="Mix" without sku_profile
  - Used with `ExpectError: regexp.MustCompile(...)`

---

**Total Valid Test Cases**: 23

**Notes**:
- Some test functions are used in multiple test scenarios (e.g., `r.linux()` is used as base config in several update tests)
- Test cases marked with "EastUS2" location override due to preview feature availability
- Several update test cases validate transitions between states (A → B)
- Priority mix and SKU profile features are preview features with specific region requirements
