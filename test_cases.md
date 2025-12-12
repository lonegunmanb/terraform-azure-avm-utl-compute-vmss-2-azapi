# Test Configuration Functions for azurerm_orchestrated_virtual_machine_scale_set

## Test Cases Summary

| case name | file url | status |
| --- | --- | --- |
| basic | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed |
| regression15299 | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed |
| evictionPolicyDelete | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed |
| specializedImage | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed |
| withPPG | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed |
| basicApplicationSecurity | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed |
| basicWindows | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed |
| otherAdditionalUnattendContent | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed |
| basicWindowsNoTimezone | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go | Completed |
| linux | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| linuxInstances | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| linuxUpdated | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| linuxCustomDataUpdated | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| bootDiagnostic | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| bootDiagnostic_noStorage | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| linuxEd25119SshKey | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| linuxKeyDataUpdated | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| applicationGatewayTemplate | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| skuProfile | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| skuProfileUpdate | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| priorityMixPolicy | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| updatePriorityMixPolicy | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |
| osProfile_empty | https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/refs/heads/main/internal/services/compute/orchestrated_virtual_machine_scale_set_resource_test.go |  |

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
