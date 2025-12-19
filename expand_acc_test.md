# expand_acc_test.md — ACC Test Case Extraction and Conversion Guide

## Part 1: Extract Test Case from Provider Test File

### Objective
Extract a test case method from the provider test file and create a complete, runnable Terraform configuration in `azurermacctest/<case_name>/main.tf`.

### Test Case Method Structure
Test cases are methods on the resource struct (e.g., `OrchestratedVirtualMachineScaleSetResource`) that return Terraform configuration strings. They follow patterns like:
- `func (OrchestratedVirtualMachineScaleSetResource) basic(data acceptance.TestData) string`
- `func (OrchestratedVirtualMachineScaleSetResource) withDataDisks(data acceptance.TestData) string`
- `func (OrchestratedVirtualMachineScaleSetResource) osProfile_empty(data acceptance.TestData) string`

Each test case method typically:
1. Returns a string using `fmt.Sprintf()` with placeholders like `%s`, `%d`
2. Interpolates random strings via `data.RandomString`
3. Interpolates random integers via `data.RandomInteger`
4. Uses location from environment variable via `data.Locations.Primary`

Example structure:
```go
func (OrchestratedVirtualMachineScaleSetResource) osProfile_empty(data acceptance.TestData) string {
	return fmt.Sprintf(`
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-%s"
  location = "%s"
}
`, data.RandomString, data.Locations.Primary)
}
```

### Extraction Steps

#### Step 1: Locate the Test Method
- Find the test case method on the resource struct (e.g., `func (OrchestratedVirtualMachineScaleSetResource) methodName(data acceptance.TestData) string`)
- Identify the Terraform configuration template string returned by `fmt.Sprintf()`
- Note all placeholders and their context

#### Step 2: Create Test Directory
- Create directory `azurermacctest/<case_name>` 
- Folder name should be snake_case, using the method name directly
- Example: `basic` → `azurermacctest/basic`
- Example: `osProfile_empty` → `azurermacctest/os_profile_empty`
- Example: `withDataDisks` → `azurermacctest/with_data_disks`

#### Step 3: Transform the Configuration

**CRITICAL RULE**: Create exactly ONE `random_string` and ONE `random_integer` resource per test case, regardless of how many placeholders exist.

##### Random String Replacements
Original test code pattern (note multiple `%s` placeholders):
```go
fmt.Sprintf(`
resource "azurerm_resource_group" "test" {
  name     = "acctestRG-%s"
  location = "%s"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name = "acctestVMSS-%s"
  ...
}
`, data.RandomString, data.Locations.Primary, data.RandomString)
```

Transform to (using a single random_string for ALL string placeholders):
```hcl
resource "random_string" "name" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "test" {
  name     = "acctestRG-${random_string.name.result}"
  location = "eastus"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "test" {
  name = "acctestVMSS-${random_string.name.result}"
  ...
}
```

##### Random Integer Replacements
Original test code pattern (note multiple `%d` placeholders):
```go
fmt.Sprintf(`
  disk_size_gb = %d
  instances = %d
`, data.RandomInteger, data.RandomInteger)
```

Transform to (using a single random_integer for ALL integer placeholders, **positive numbers only**):
```hcl
resource "random_integer" "number" {
  min = 10000
  max = 100000
}

# In the resource blocks:
disk_size_gb = random_integer.number.result
instances = random_integer.number.result
```

**IMPORTANT**: Always set `min >= 1` for random_integer to ensure positive numbers only.

##### Location Replacements
- Replace `data.Locations.Primary` → `"eastus"`
- Replace `data.Locations.Secondary` → `"westus"` (if needed)

#### Step 4: Generate Complete main.tf

Include these sections in order:

1. **Terraform block** (required)
2. **Provider blocks**:
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azapi" {}

provider "random" {}
```

3. **Random resource definitions** (exactly one random_string and one random_integer resource)
4. **Main resources** (the actual test configuration with placeholders replaced by references to the single random resources)

#### Step 5: Validate
- Ensure all placeholders are replaced
- Ensure all resources have valid references
- Ensure no hardcoded random values (use random provider instead)
- Ensure the configuration is syntactically correct HCL

### Naming Conventions

#### Folder Names
- Use snake_case, convert method name directly
- Example: `basic` → `azurermacctest/basic`
- Example: `osProfile_empty` → `azurermacctest/os_profile_empty`
- Example: `withDataDisks` → `azurermacctest/with_data_disks`

#### Random Resource Names
**Use these standard names** (one of each per test case):
- `random_string.name` - the single random string resource for all string placeholders
- `random_integer.number` - the single random integer resource for all integer placeholders (min >= 100000  and max < 1000000 for positive numbers only)

### Best Practices

- **Preserve Test Logic**: Ensure the extracted configuration maintains the same resource dependencies and structure as the original test
- **Use Reasonable Random Ranges**: 
  - String length: 8 characters (special=false, upper=false for most Azure resources)
  - Integer ranges: Choose appropriate min/max based on context (e.g., instances: 1-10, disk_size: 10-1000)
- **Complete Configuration**: Every `main.tf` must be runnable standalone with all required providers
- **Single Random Resources**: Only one `random_string` and one `random_integer` per test case, reused across all placeholders

---

## Part 2: Convert AzureRM Resources to AzAPI Module

> Role: ACC test conversion agent. Goal: rewrite `azurerm_*` resources in `azurermacctest/<case>/main.tf` into an equivalent implementation using a `module` (`source = ../..`) plus `azapi_resource`/`azapi_update_resource`, and configure the corresponding `moved` block. You can infer the actual type of AzureRM resource by reading `../../track.md`.

## Inputs
- `azurermacctest/<case>/main.tf`
- Root module variable definitions: `../../variables.tf`, `../../migrate_variables.tf`
- Root module output definitions: `../../outputs.tf`
- Resource type & path: target resource listed in `../../track.md`

## Outputs
- `azurermacctest/<case>/azurerm.tf`
  - **Only** the original target AzureRM resource block (cut from `main.tf`).
- `azurermacctest/<case>/azapi.tf.bak`
  1. `module "vmss_replicator" { source = "../.." ... }`: pass arguments equivalently; convert all nested blocks into object/list/set literals.
  2. `resource "azapi_resource" "this" { ... }`: consume module outputs (`azapi_header`, `body`, `sensitive_body`, `sensitive_body_version`, `replace_triggers_external_values`, `post_creation_updates`, `locks`).
  3. **Optional** `resource "azapi_update_resource" "vmss"`: when `module.vmss_replicator.post_creation_updates` is non-empty, create one update resource per entry.
  4. `moved` block: from AzureRM resource address to new AzAPI resource address.
- `azurermacctest/<case>/main.tf`: keep providers, `random_*`, `azurerm_resource_group`, etc.; **remove** the original VMSS resource block.

Example:

```hcl
module "vmss_replicator" { #`vmss_replicator` here is just for example
  source = "../../"
  orchestrated_virtual_machine_scale_set_name = "example-vmss"
  # ...
}

resource "azapi_resource" "this" {
  type      = module.vmss_replicator.azapi_header.type
  name      = module.vmss_replicator.azapi_header.name
  parent_id = module.vmss_replicator.azapi_header.parent_id
  body      = module.vmss_replicator.body
  
  replace_triggers_external_values = module.vmss_replicator.replace_triggers_external_values
}
```

## Steps
1. **Locate & extract the AzureRM resource**
   - In `azurermacctest/<case>/main.tf`, find target resource(You can infer the actual type of AzureRM resource by reading `../../track.md`).
   - Cut it to `azurermacctest/<case>/azurerm.tf` verbatim.

2. **Build the module call (write to `azapi.tf.bak`)**
   - Module source: `source = "../.."`.
   - **Map** resource arguments to root module variables:
     - **Scalars**: pass through directly (e.g., `name`, `resource_group_name`, `location`, `instances`).
     - **Nested blocks**: rewrite as object/list/set literals per `variables.tf` type definitions.
       - Example: `os_profile { ... }` → `os_profile = { linux_configuration = { ... } }`
       - Lists: `[...]`; sets: `toset([...])` or `set([...])` (match `variables.tf`).
     - **Multi-instance blocks** (e.g., `network_interface`): build arrays/sets of objects.
   - **Handle migrated fields (tagged with `# TODO: delete later`)**:
     - Do **not** pass the legacy field; use replacement variables from `migrate_variables.tf`.
     - How to find replacements: search `../../ migrate_variables.tf` for the field path keyword (e.g., `custom_data`, `admin_password`, `protected_settings`), pass the corresponding `migrate_<...>` variable, and remove the old field from the object literal.
     - **IMPORTANT - Ephemeral version variables**: If a `migrate_` variable has a corresponding `*_version` variable (used to trigger ephemeral updates), **both variables must be assigned together**. When assigning the value, you must also assign a version (e.g., increment a number or use a timestamp). Never assign only one without the other.
       - Example: If using `migrate_..._custom_data`, you must also assign `migrate_..._custom_data_version = 1` (or any non-null value).
     - Common migration examples (confirm actual names in files):
       - `os_profile.custom_data` → `migrate_..._os_profile_custom_data` (keep base64 string) + `migrate_..._os_profile_custom_data_version`.
       - `os_profile.linux_configuration.admin_password` → `migrate_..._linux_configuration_admin_password` + `migrate_..._linux_configuration_admin_password_version`.
       - `os_profile.windows_configuration.admin_password` → `migrate_..._windows_configuration_admin_password` + `migrate_..._windows_configuration_admin_password_version`.
       - `extension.protected_settings` → `migrate_..._extension_protected_settings` (or similar) + corresponding `*_version` variable.

3. **Generate `azapi_resource` (write to `azapi.tf.bak`)**
   - Use module outputs:
     ```hcl
     resource "azapi_resource" "this" {
       type                      = module.vmss_replicator.azapi_header.type
       name                      = module.vmss_replicator.azapi_header.name
       location                  = module.vmss_replicator.azapi_header.location
       parent_id                 = module.vmss_replicator.azapi_header.parent_id
       tags                      = module.vmss_replicator.azapi_header.tags
       body                      = module.vmss_replicator.body
       ignore_null_property      = module.vmss_replicator.azapi_header.ignore_null_property
       sensitive_body            = module.vmss_replicator.sensitive_body
       sensitive_body_version    = module.vmss_replicator.sensitive_body_version
       replace_triggers_external_values = module.vmss_replicator.replace_triggers_external_values
       locks                     = module.vmss_replicator.locks
       retry                     = module.vmss_replicator.retry

       dynamic "identity" {
        for_each = can(module.vmss_replicator.azapi_header.identity) ? [module.vmss_replicator.identity] : []
        content {
          type = identity.value.type
          identity_ids = try(identity.value.identity_ids, null)
        }
       }

       dynamic "timeouts" {
        for_each = module.vmss_replicator.timeouts != null ? [module.vmss_replicator.timeouts] : []
        content {
          create = timeouts.value.create
          delete = timeouts.value.delete
          read   = timeouts.value.read
          update = timeouts.value.update
        }
       }
     }
     ```
   - **Timeouts**: If module outputs `timeouts`, assign its `create`, `delete`, `read`, and `update` values to the corresponding `timeouts` block fields in `azapi_resource`.
   - **Post-creation updates**: if `module.vmss_replicator.post_creation_updates` is non-empty:
     - Read the root module's `../../migrate_main.tf` to check how many members are defined in `local.post_creation_updates`.
     - Create **one separate `azapi_update_resource` block per member** (e.g., `update0`, `update1`, etc.).
     - **Serialize execution using `depends_on`**: The first update resource has no `depends_on`; each subsequent resource depends on the previous one.
     - Example (assuming 2 members in `post_creation_updates`):
       ```hcl
       resource "azapi_update_resource" "update0" {
         type           = module.vmss_replicator.post_creation_updates[0].azapi_header.type
         name           = module.vmss_replicator.post_creation_updates[0].azapi_header.name
         parent_id      = module.vmss_replicator.post_creation_updates[0].azapi_header.parent_id
         body           = module.vmss_replicator.post_creation_updates[0].body
         sensitive_body = try(module.vmss_replicator.post_creation_updates[0].sensitive_body, null)
         depends_on     = [azapi_resource.this]
         lifecycle {
           ignore_changes = all
         }
       }
       
       resource "azapi_update_resource" "update1" {
         type           = module.vmss_replicator.post_creation_updates[1].azapi_header.type
         name           = module.vmss_replicator.post_creation_updates[1].azapi_header.name
         parent_id      = module.vmss_replicator.post_creation_updates[1].azapi_header.parent_id
         body           = module.vmss_replicator.post_creation_updates[1].body
         sensitive_body = try(module.vmss_replicator.post_creation_updates[1].sensitive_body, null)
         depends_on     = [azapi_update_resource.update0]
         lifecycle {
           ignore_changes = all
         }
       }
       ```

4. **`moved` block (write to `moved.tf.bak`)**
   ```hcl
   moved {
     from = <azurerm_type>.<NAME>
     to   = azapi_resource.this
   }
   ```
   - `<NAME>` must match the original resource name.

5. **File structure requirements**
   - **IMPORTANT**: `azapi.tf.bak` must NOT contain `terraform` blocks or `provider` blocks
   - `azapi.tf.bak` should only contain: module call, `azapi_resource`, and optional `azapi_update_resource` blocks
   - All provider configurations remain in `main.tf`

6. **Validate**
   - Ensure the module call shape matches `../.. / variables.tf` (object fields, list/set types).
   - Ensure all migrated fields use the corresponding `migrate_` variables and are not present in object literals.
   - Do **not** modify root module files.

## Notes
- When converting nested blocks to objects, keep field names aligned with `variables.tf`; use `tolist()/toset()` for type compatibility as needed.
- If a replacement variable name is unclear, first check `migrate_variables.tf`; if still unknown, keep the original field **and** add a top-of-file comment marking it for follow-up.
- Do **not** change resource semantics, names, or remove test helper resources.
- This file is guidance only; when executing, follow general rules from `executor.md`/`coordinator.md`.