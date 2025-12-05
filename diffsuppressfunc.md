# DiffSuppressFunc Handling

**When to use this guide:** If Provider schema shows `DiffSuppressFunc` for current field, follow this document's rules. This overrides standard ForceNew handling.

## What is DiffSuppressFunc?

`DiffSuppressFunc` is a Provider function that suppresses differences under certain conditions. It prevents Terraform from detecting changes when specific conditions are met, even if the actual values differ.

**Example from provider:**
```go
"network_api_version": {
    Type:         pluginsdk.TypeString,
    Optional:     true,
    Default:      "2020-11-01",
    DiffSuppressFunc: func(_, old, new string, d *pluginsdk.ResourceData) bool {
        if _, ok := d.GetOk("sku_name"); !ok {
            if old == "" && new == "2020-11-01" {
                return true  // Suppress diff
            }
        }
        return false  // Do not suppress
    },
}
```

## Three-Part Implementation Strategy

When a field has `DiffSuppressFunc`:

**Part 1:** Add field path to `local.ignore_changes` (prevents main resource updates)

**Part 2:** Set field normally in main `body` (initial creation)

**Part 3:** Construct trigger variable + add to `post_creation_updates` (handles real updates)

### Part 1: Add to `ignore_changes`

**Purpose:** Prevent main `azapi_resource` from triggering updates based on this field.

```hcl
locals {
  ignore_changes = [
    "properties.path.to.field"  # JSON path format
  ]
}
```

**Path format:** Use JSON path notation matching Azure API response structure.

### Part 2: Set Initial Value in `body`

Handle this field normally - apply defaults, transformations, etc. as specified in Provider schema. The field MUST be present in main `body` for initial resource creation.

```hcl
locals {
  body = {
    properties = {
      # Normal field assignment - follow standard executor rules
      field = local.field_value
    }
  }
}
```

### Part 3: Construct Update Trigger

**Goal:** Create a trigger variable that controls `azapi_update_resource` recreation.

**Required behavior:**
- Return **non-null** when update is required (DiffSuppressFunc would return false)
- Return **`null`** when update should be suppressed (DiffSuppressFunc would return true)

**Steps:**

1. **Read existing state if needed** (not always required - depends on DiffSuppressFunc logic):
```hcl
locals {
  existing_field_value = try(
    data.azapi_resource.existing.output.properties.path.to.field,
    null
  )
}
```

2. **Translate DiffSuppressFunc logic EXACTLY to Terraform:**
```hcl
locals {
  # Compute suppress condition
  field_should_suppress = (
    # Translate DiffSuppressFunc conditions here
  )

  # Construct trigger: null when suppressed, non-null when update needed
  field_update_trigger = !local.field_should_suppress ? some_non_null_value : null
}
```

3. **Add to `post_creation_updates`:**
```hcl
locals {
  post_creation_updates = compact([
    {
      azapi_header = { ... }
      body = { properties = { field = local.field_value } }
      replace_triggers_external_values = {
        field = local.field_update_trigger  # Direct assignment, no wrapping
      }
    }
  ])
}
```

**Key points:**
- The update object is always present (not conditional)
- The trigger key is always present
- Only the trigger VALUE switches between `null` and non-null
- Don't wrap trigger in `{ value = ... }` - direct assignment only

## Complete Example

**Task:** Implement `network_api_version` field with DiffSuppressFunc.

**Provider schema:**
```go
"network_api_version": {
    Type:         pluginsdk.TypeString,
    Optional:     true,
    Default:      "2020-11-01",
    DiffSuppressFunc: func(_, old, new string, d *pluginsdk.ResourceData) bool {
        if _, ok := d.GetOk("sku_name"); !ok {
            if old == "" && new == "2020-11-01" {
                return true
            }
        }
        return false
    },
}
```

**Implementation:**

```hcl
locals {
  # Read existing state
  existing_network_api_version = try(
    data.azapi_resource.existing.output.properties.virtualMachineProfile.networkProfile.networkApiVersion,
    ""
  )

  # Apply default
  new_network_api_version = coalesce(
    var.orchestrated_virtual_machine_scale_set_network_api_version,
    "2020-11-01"
  )

  # Replicate DiffSuppressFunc logic
  network_api_version_should_suppress = (
    var.orchestrated_virtual_machine_scale_set_sku_name == null &&
    local.existing_network_api_version == "" &&
    local.new_network_api_version == "2020-11-01"
  )

  # Compute update trigger
  network_api_version_update_trigger = (
    !local.network_api_version_should_suppress &&
    local.existing_network_api_version != local.new_network_api_version
  ) ? local.new_network_api_version : null

  # Part 1: Ignore changes
  ignore_changes = [
    "properties.virtualMachineProfile.networkProfile.networkApiVersion"
  ]

  # Part 2: Set in main body
  body = {
    properties = {
      virtualMachineProfile = {
        networkProfile = {
          networkApiVersion = local.new_network_api_version
        }
      }
    }
  }

  # Part 3: Conditional update
  post_creation_updates = compact([
    {
      azapi_header = {
        type      = "Microsoft.Compute/virtualMachineScaleSets@2024-11-01"
        name      = var.orchestrated_virtual_machine_scale_set_name
        parent_id = var.orchestrated_virtual_machine_scale_set_resource_group_id
      }
      body = {
        properties = {
          virtualMachineProfile = {
            networkProfile = {
              networkApiVersion = local.new_network_api_version
            }
          }
        }
      }
      replace_triggers_external_values = {
        network_api_version = local.network_api_version_update_trigger
      }
    }
  ])
}
```

## Proof Document Requirements

When documenting DiffSuppressFunc implementation, proof must include:

1. **DiffSuppressFunc Source:** Quote complete Go function from provider
2. **Logic Translation:** Show exact translation to Terraform
3. **Three-Part Evidence:**
   - `ignore_changes` list with correct JSON path
   - `body` setting with default applied
   - `post_creation_updates` with trigger logic
4. **Trigger Logic Verification:** Explain when trigger is null vs non-null
5. **Test Cases:** Document scenarios where suppress=true and suppress=false

## Common Mistakes

❌ **WRONG:** Only set field in `post_creation_updates`, not in main `body`
```hcl
body = {}  # Field missing!
post_creation_updates = [{ body = { field = value } }]
```

❌ **WRONG:** Make update object conditional
```hcl
post_creation_updates = compact([
  local.field_update_trigger != null ? {  # Wrong!
    replace_triggers_external_values = { field = local.field_update_trigger }
  } : null
])
```

❌ **WRONG:** Wrap trigger value in object
```hcl
replace_triggers_external_values = {
  field = { value = local.field_update_trigger }  # Wrong! No wrapping for triggers
}
```

✅ **CORRECT:**
```hcl
# Set in main body
body = { properties = { field = local.field_value } }

# Always-present update with null-switching trigger
post_creation_updates = compact([
  {
    body = { properties = { field = local.field_value } }
    replace_triggers_external_values = {
      field = local.field_update_trigger  # null or non-null
    }
  }
])
```

## Summary Checklist

When implementing field with DiffSuppressFunc:

- ✅ Quote complete `DiffSuppressFunc` Go code in proof
- ✅ Add field path to `local.ignore_changes`
- ✅ Set field in main `local.body` with defaults applied
- ✅ Read existing state via `data "azapi_resource"`
- ✅ Translate DiffSuppressFunc logic EXACTLY to compute suppress flag
- ✅ Compute update trigger: `(!suppress && value_changed) ? new_value : null`
- ✅ Add always-present member to `post_creation_updates`
- ✅ Include `replace_triggers_external_values` with direct assignment (no wrapping)
- ✅ Document all three parts in proof
- ✅ Test both suppress and non-suppress scenarios
