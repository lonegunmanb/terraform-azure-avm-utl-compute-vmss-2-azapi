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

## Two-Part Implementation Strategy

When a field has `DiffSuppressFunc`:

**Part 1:** Set field in `sensitive_body` with `sensitive_body_version` tracking (initial creation only, prevents automatic updates)

**Part 2:** Construct trigger variable + add to `post_creation_updates` (handles real updates)

### Part 1: Set Initial Value in `sensitive_body`

Set the field in `sensitive_body` and track it in `sensitive_body_version` using a constant value to ensure it never triggers updates automatically. Apply defaults, transformations, etc. as specified in Provider schema.

```hcl
locals {
  sensitive_body = {
    properties = {
      # Field assignment - follow standard executor rules
      field = local.field_value
    }
  }
  
  # Track field with constant "null" to prevent automatic updates
  sensitive_body_version = {
    "properties.path.to.field" = "null"  # Constant value ensures no updates
  }
}
```

### Part 2: Construct Update Trigger

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

  # Part 1: Set in sensitive_body with constant version tracking
  sensitive_body = {
    properties = {
      virtualMachineProfile = {
        networkProfile = {
          networkApiVersion = local.new_network_api_version
        }
      }
    }
  }
  
  # Track with constant "null" to prevent automatic updates
  sensitive_body_version = {
    "properties.virtualMachineProfile.networkProfile.networkApiVersion" = "null"
  }

  # Part 2: Conditional update
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
3. **Two-Part Evidence:**
   - `sensitive_body` setting with default applied and `sensitive_body_version` map with constant "null" value
   - `post_creation_updates` with trigger logic
4. **Trigger Logic Verification:** Explain when trigger is null vs non-null
5. **Test Cases:** Document scenarios where suppress=true and suppress=false

## Common Mistakes

❌ **WRONG:** Set field in main `body` instead of `sensitive_body`
```hcl
body = { properties = { field = value } }  # Wrong! Should use sensitive_body
```

❌ **WRONG:** Use dynamic version tracking in `sensitive_body_version`
```hcl
sensitive_body_version = {
  "properties.path.to.field" = try(tostring(var.field_version), "null")  # Wrong! Should be constant
}
```

❌ **WRONG:** Only set field in `post_creation_updates`, not in `sensitive_body`
```hcl
sensitive_body = {}  # Field missing!
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
# Set in sensitive_body with constant version tracking
sensitive_body = { properties = { field = local.field_value } }
sensitive_body_version = {
  "properties.path.to.field" = "null"
}

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
- ✅ Set field in `local.sensitive_body` with defaults applied
- ✅ Set `sensitive_body_version = { "properties.path.to.field" = "null" }` (constant value, never changes)
- ✅ Read existing state via `data "azapi_resource"`
- ✅ Translate DiffSuppressFunc logic EXACTLY to compute suppress flag
- ✅ Compute update trigger: `(!suppress && value_changed) ? new_value : null`
- ✅ Add always-present member to `post_creation_updates`
- ✅ Include `replace_triggers_external_values` with direct assignment (no wrapping)
- ✅ Document both parts in proof
- ✅ Test both suppress and non-suppress scenarios
