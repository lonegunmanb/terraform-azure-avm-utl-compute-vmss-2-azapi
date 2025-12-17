# Timeouts Block Handling

**⚠️ CRITICAL:** The `timeouts` block is a Terraform provider meta-argument, NOT an Azure API property. It controls operation timeout durations, not request/response data.

**Implementation Location:** Timeouts are NOT implemented in shadow module's `locals`. They are handled in the parent module's `azapi_resource` block directly.

## Executor Tasks for Timeouts (#160-164)

When processing timeout-related tasks, you MUST:

### 1. Read Default Timeout Values from Provider Source Code

**For Old SDK Resources** (using `pluginsdk`):
- Query the complete resource function: `query_golang_source_code(symbol="func", name="resource{ResourceName}")`
- Look for the `Timeouts` field in the resource schema:
  ```go
  Timeouts: &pluginsdk.ResourceTimeout{
      Create: pluginsdk.DefaultTimeout(60 * time.Minute),
      Read:   pluginsdk.DefaultTimeout(5 * time.Minute),
      Update: pluginsdk.DefaultTimeout(60 * time.Minute),
      Delete: pluginsdk.DefaultTimeout(60 * time.Minute),
  }
  ```
- Extract the default values for each operation (Create, Read, Update, Delete)

**For New Framework Resources** (using `github.com/hashicorp/terraform-provider-azurerm/internal/sdk`):
- Query each CRUD method separately:
  - `query_terraform_block_implementation_source_code(entrypoint_name="create")`
  - `query_terraform_block_implementation_source_code(entrypoint_name="read")`
  - `query_terraform_block_implementation_source_code(entrypoint_name="update")`
  - `query_terraform_block_implementation_source_code(entrypoint_name="delete")`
- Look for the `Timeout` field in each method's return value:
  ```go
  func (r CognitiveDeploymentResource) Create() sdk.ResourceFunc {
      return sdk.ResourceFunc{
          Timeout: 30 * time.Minute,
          Func: func(ctx context.Context, metadata sdk.ResourceMetaData) error {
              // ...
          },
      }
  }
  ```
- Extract the timeout value for the corresponding operation

### 2. Update Variable Defaults in `variables.tf`

**⚠️ CRITICAL REQUIREMENTS:**
1. **Sync `default` with `type` definition:** The values in the `default` block MUST exactly match the default values defined in the `optional(string, "XXm")` parameters in the `type` definition
2. **Set `nullable = false`:** Always ensure `nullable = false` is explicitly set to prevent null values

- Locate the existing timeout variable (e.g., `orchestrated_virtual_machine_scale_set_timeouts`)
- Update the `default` value for the specific timeout field:
  ```hcl
  variable "orchestrated_virtual_machine_scale_set_timeouts" {
    type = object({
      create = optional(string, "60m")  # <- Update with extracted default
      delete = optional(string, "60m")  # <- Update with extracted default
      read   = optional(string, "5m")   # <- Update with extracted default
      update = optional(string, "60m")  # <- Update with extracted default
    })
    default     = {
      create = "60m" # <- MUST match type definition: optional(string, "60m")
      delete = "60m"  # <- MUST match type definition: optional(string, "60m")
      read   = "5m"   # <- MUST match type definition: optional(string, "5m")
      update = "60m"  # <- MUST match type definition: optional(string, "60m")
    }
    nullable = false # <- REQUIRED: Always set to false
    description = <<-EOT
     - `create` - (Optional) Specifies the timeout for create operations. Defaults to 60 minutes.
     - `delete` - (Optional) Specifies the timeout for delete operations. Defaults to 60 minutes.
     - `read` - (Optional) Specifies the timeout for read operations. Defaults to 5 minutes.
     - `update` - (Optional) Specifies the timeout for update operations. Defaults to 60 minutes.
    EOT
  }
  ```
- Convert Go duration to string format: `60 * time.Minute` → `"60m"`, `30 * time.Minute` → `"30m"`
- **Verify synchronization:** Double-check that each field in `default` block matches its corresponding `optional(string, "XXm")` value

### 3. Update Variable Description

- Update the corresponding line in the description to reflect the correct default value
- Format: `- \`{operation}\` - (Optional) Specifies the timeout for {operation} operations. Defaults to {X} minutes.`

### 4. Shadow Module Implementation

- **NO CODE CHANGES** in shadow module's `migrate_*` files for body/sensitive_body/etc.
- The `timeouts` block is consumed directly by parent module's `azapi_resource`

**⚠️ IMPORTANT - Output Configuration:**

If a `timeouts` variable exists in `variables.tf`, check `migrate_outputs.tf`:
- **If `output "timeouts"` does NOT exist:** You MUST add it:
  ```hcl
  output "timeouts" {
    value = var.timeouts
  }
  ```
- **If `output "timeouts"` already exists:** No changes needed

This output allows the parent module to pass the timeouts value directly to its `azapi_resource` block.

### 5. Proof Document

- Document the provider schema evidence showing default timeout values
- Show the Go code excerpt with exact timeout definitions
- Explain that no shadow module implementation is needed
- Show the variable update with correct defaults

## Example Task Flow for Task #161 (timeouts.create)

```markdown
## Create Phase Verification

**Pattern:** Meta-block (N/A for Azure API)

From `resourceOrchestratedVirtualMachineScaleSet()`:

```go
Timeouts: &pluginsdk.ResourceTimeout{
    Create: pluginsdk.DefaultTimeout(60 * time.Minute),
    // ...
}
```

**Evidence:**
- Default value: **60 minutes**
- This is a resource-level meta-argument, not a request body property

## Implementation

Updated `variables.tf`:

```hcl
variable "orchestrated_virtual_machine_scale_set_timeouts" {
  type = object({
    create = optional(string, "60m")  # <- Added default from provider
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
   - `create` - (Optional) Specifies the timeout for create operations. Defaults to 60 minutes.
   - `delete` - (Optional) Specifies the timeout for delete operations.
   - `read` - (Optional) Specifies the timeout for read operations.
   - `update` - (Optional) Specifies the timeout for update operations.
  EOT
}
```

**Note:** No shadow module implementation required - parent module handles timeouts directly.
```

## Completion Checklist for Timeout Tasks

- ✅ Queried provider source code for timeout defaults
- ✅ Updated variable `default` value with correct timeout string
- ✅ Updated variable `description` with correct default duration
- ✅ Documented provider schema evidence in proof
- ✅ Confirmed no shadow module changes needed
- ✅ Updated `track.md` status to Pending for check
