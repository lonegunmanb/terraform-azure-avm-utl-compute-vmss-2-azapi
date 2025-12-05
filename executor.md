# Executor Agent Instructions

## Shadow Module Usage Context

**Critical Understanding:** This Shadow Module's outputs feed user's `azapi_resource` blocks. AzAPI provider has NO built-in logic from AzureRM provider - no automatic validations, no defaults, no type coercions. When users migrate from `azurerm_*` to `azapi_resource`, they lose ALL provider-level protections.

**Your Responsibility:** Replicate EVERY behavior from AzureRM provider:
- ❌ **NEVER assume** "Azure API will validate this"
- ❌ **NEVER assume** "Provider will apply defaults"
- ❌ **NEVER assume** "Type system will catch errors"
- ❌ **NEVER choose** "more conservative" or "simpler" logic for safety
- ✅ **ALWAYS replicate** validations explicitly in `variables.tf`
- ✅ **ALWAYS replicate** defaults explicitly in `variables.tf`
- ✅ **ALWAYS replicate** all provider logic EXACTLY in `locals`
- ✅ **IF EXACT replication impossible** → FAIL task and document in error.md

**CRITICAL RULE - EXACT REPLICATION ONLY:**
When implementing ANY logic from AzureRM provider (validations, defaults, conditionals, transformations, ForceNew, CustomizeDiff, expand/flatten functions), you have TWO options:
1. ✅ Replicate the EXACT behavior from provider source code
2. ✅ FAIL the task if exact replication is technically impossible

You do NOT have permission to choose "safer" or "simpler" alternatives. Users depend on this Shadow Module to provide the SAME behavior as the original AzureRM provider.

## Core Mission
Build `locals` in Shadow Module (`migrate_*` files) for `azapi_resource` body. ONE task at a time.
**⚠️ Scope:** ONLY implement SPECIFIC field in task. Ignore other fields in source code.
**⚠️ Critical Self-Review:** After completing implementation, critically review ALL changes made. Ask yourself:
- Did I add ONLY what this specific task requires?
- Did I add hidden fields that belong to `__check_*_hidden_fields__` tasks?
- Did I add fields from other tasks?
- Remove any content that belongs to other tasks immediately.
**Files:** `migrate/` has: `main.tf` (NO modify), `variables.tf` (modify when documented: default/ephemeral/validation/etc.) | `migrate_main.tf`, `migrate_variables.tf`, `migrate_outputs.tf`, `migrate_validation.tf` (edit) | `track.md`

## Schema Investigation
**MANDATORY:** Query complete resource function FIRST to get `CustomizeDiff` (critical for ForceNew):
```
query_golang_source_code(symbol="func", name="resource{ResourceName}")  # Returns full resource including CustomizeDiff
query_terraform_block_implementation_source_code(entrypoint_name="schema")  # Returns field details
```
**⚠️ CRITICAL:** `CustomizeDiff` (e.g., `ForceNewIfChange`) is NOT in schema query - must query complete resource function.
**Recovery:** Verify params → Try variations → Fallback `github_repo`
**FALLBACK:** `query_terraform_schema` if source unavailable

**Azure API Schema Tips:**
- If `query_azapi_resource_schema(path="field")` fails, query full schema without path to locate the field
- In `azapi_resource`: ONLY `type`, `location`, `name`, `parent_id`, `identity`, `tags` go to root; ALL other fields (including root-level API fields like `zones`, `sku`) go inside `body`

## Field-Related Logic Discovery

**MANDATORY:** Query ALL locations for logic involving current field:

1. **Resource function** (`symbol=func, name=resource{ResourceName}`) - CustomizeDiff
2. **CRUD methods** - Create, Read, Update, Delete (`entrypoint=create/read/update/delete`)
3. **Expand/Flatten functions** - if field uses expand/flatten

**Search patterns (old SDK):** `d.Get("field")`, `raw["field"]`, `diff.Get("field")`, `d.HasChange("field")`
**Search patterns (new framework):** `data.FieldName`, `state.FieldName`, `plan.FieldName`, `model.FieldName`
**Both:** Error messages mentioning field name

**Identify logic type and implement:**
- **Validation** (returns error) → `variables.tf` validation block
- **ForceNew** (old/new comparison) → `replace_triggers_external_values` + `data "azapi_resource"`
- **Update restriction** (Update returns error) → conditional ForceNew
- **Computed/conditional** → `locals.body` or defer

**Trigger condition rule:** If error mentions current field AND trigger condition involves current field → implement in current task. If referenced variables don't exist → mark `BLOCKED: Task #X`.

## Validation Rules
**CRITICAL:** AzureRM validations don't execute with AzAPI. We MUST replicate ALL documented validations. Relying on Azure API for validation is NOT acceptable - it's too slow and provides poor user experience.

**Implementation Requirements:**
- **MANDATORY:** Every validation found in the provider schema MUST be implemented in `variables.tf`
- **NO DEFERRAL:** Do NOT defer validations to Azure API checks
- **IMMEDIATE:** Validations must fail fast at Terraform plan time, not during API calls

**Category 1 - Value Constraints (MUST ALL):**
Replicate `StringInSlice`, `IntBetween`, `IntAtLeast`, `IntAtMost`, `StringMatch`, `FloatBetween` for value constraints.
- ❌ Skip ONLY Azure Resource ID format validations (e.g., `/subscriptions/.../resourceGroups/...`) - these are verified by resource references
- ✅ **MUST** add name format validations (e.g., length, character patterns)
- ✅ **MUST** add enum value validations
- ✅ **MUST** add numeric range validations
- Action: Modify variable in `variables.tf` to add `validation` block

**Category 2 - Cross-Field Constraints (MUST ALL):**
`ConflictsWith`, `RequiredWith`, `ExactlyOneOf`, `AtLeastOneOf` → Modify field's variable in `variables.tf` to add `validation` block (ownership rule). If referenced var doesn't exist, document & defer to later task that creates that variable.

**⚠️ IMPORTANT - Terraform 1.9+ Cross-Variable Validation:**
Starting from Terraform 1.9, `variable` validation blocks CAN reference other variables. This means cross-variable validations (e.g., when field A is set, field B must also be set, where A and B are different variables) MUST be implemented in `variables.tf` validation blocks, NOT in `migrate_validation.tf`.

**Cross-Variable Validation Implementation Rules:**
- ✅ **MUST** implement cross-variable validations in the "owning" variable's validation block in `variables.tf`
- ✅ **MUST** reference other variables directly (e.g., `var.other_field`) in validation condition
- ❌ **NEVER** defer cross-variable validations to `migrate_validation.tf` unless technically impossible
- ❌ **NEVER** create root-level `check` blocks in `migrate_validation.tf` - this is PROHIBITED

**PROHIBITED - Root-Level Check Blocks:**
```hcl
# ❌ NEVER create this in migrate_validation.tf
check "some_validation" {...}
```

**Category 3 - Custom Logic (MUST ALL SIMPLE):**
Replicate simple validation logic. Skip ONLY complex Azure queries that require API calls to verify resource existence.

**Defaults:** If schema has `Default`, replicate it:
- **Top-level:** `variable "field" { default = value }`
- **Nested (PREFER):** `optional(bool, true)` or `optional(string, "PT1H30M")` in object type
- **Fallback:** Apply default in locals if optional() syntax not possible

## Locals Structure

### 1. `azapi_header`
```hcl
locals {
  azapi_header = {
    type = "<ResourceType>@<ApiVersion>"  # From track.md AzAPI Target Resource
    name = var.{prefix}_name; location = var.{prefix}_location; parent_id = var.{prefix}_{parent_type}_id
    # ONLY these 5 fields allowed: type, name, location, parent_id, identity
    # identity = ... (if resource supports managed identity at root level)
  }
}
```
**Note:** Root-level API fields like `zones`, `tags`, `sku` go in `body`, NOT `azapi_header`.

### 2. `body` - Non-Sensitive
⚠️ `merge()` is SHALLOW! Use nested `merge()` for shared paths:
```hcl
locals {
  body = {
    properties = merge(
      { topField = var.top },
      { sharedParent = merge(var.a != null ? { childA = "v" } : {}, var.b != null ? { childB = "v" } : {}) }
    )
    sku = var.sku_name != null ? { name = var.sku_name } : null
    zones = var.zones  # Root-level API fields go in body
    tags = var.tags    # Root-level API fields go in body
  }
}
```

### 3. `sensitive_body` & `sensitive_body_version`
```hcl
locals {
  sensitive_body = { properties = { ... } }
  sensitive_body_version = { "path.to.field" = var.field_version }
}
```

### 4. `replace_triggers_external_values` - ForceNew

**CRITICAL:** Check BOTH schema `ForceNew: true` AND resource function `CustomizeDiff` (e.g., `ForceNewIfChange`, `ForceNewIf`).

**MANDATORY: Stable Keys** - Keys MUST NOT appear/disappear across applies (causes unnecessary replacements).

❌ `merge({ a = {...} }, cond ? { b = {...} } : {})` ← Key `b` unstable
✅ `{ a = {...}, b = { value = cond ? val : "" } }` ← Key `b` always present

**Understanding `value` in replace_triggers_external_values:**

The `value` field serves as a **change detector**. When Terraform detects that `value` has changed between applies, it triggers resource replacement. You must carefully design what `value` contains:

- **Key Principle**: The `value` should change **if and only if** the condition that requires replacement is met
- **When the expected change occurs** → `value` should reflect that change
- **When the expected change does NOT occur** → `value` should remain stable (often `null` or empty)

**Simple ForceNew (schema `ForceNew: true`):**
```hcl
# The field value itself is the condition - any change triggers replacement
field = { value = var.field }
```

**Conditional ForceNew (CustomizeDiff with logic):**

Think carefully: What change should trigger replacement?

```hcl
# Example 1: Only trigger replacement when removing items
# value = boolean flag that becomes true only when removal detected
field = { value = local.field_removal_detected }  # true/false based on comparison

# Example 2: Only trigger replacement when specific conditions met
# value = the condition result itself, not the data
field = { value = local.should_replace_due_to_field }  # Computed boolean
```

**Common Mistake - Don't do this:**
```hcl
# ❌ WRONG: Putting the actual data in value when you need conditional logic
# This triggers replacement on ANY change, not just the specific condition
field = { value = var.field_list }

# ❌ WRONG: Inventing non-existent parameters
field = {
  value = var.field
  force_new_on_value = some_condition  # This parameter doesn't exist!
}
```

**Correct Approach:**
```hcl
# ✅ RIGHT: Value is the trigger condition, not the data itself
field = { value = local.field_should_trigger_replacement }

# Where local.field_should_trigger_replacement is computed from:
# - Reading existing state via data "azapi_resource"
# - Comparing old vs new values
# - Returning boolean: true = should replace, false = should not replace
```

**CustomizeDiff - EXACT Replication Steps:**
1. Quote FULL Go code in proof document
2. Translate EXACTLY to Terraform - NO simplifications
3. Use `data "azapi_resource"` to read existing state if needed for old/new comparison
4. Implement the SAME conditional logic
5. **Design `value` thoughtfully** - it should represent "should I trigger replacement?" not "what is the data?"
6. **Keep all keys stable** - use empty values instead of conditionally adding keys

If exact replication impossible, FAIL the task and document why in error.md.

### 5. `post_creation_updates` - Two-Phase
Field set in Update phase (after Create in Create method):
```hcl
locals {
  post_creation_updates = compact([
    var.field != null ? {
      azapi_header = { type = "..." }  # Usually same as main, verify from Update client
      body = { properties = {...} }; sensitive_body = {...}
    } : null,
  ])
}
```

### 6. `locks` - Dependency Locking
List of lock strings extracted from Provider's CRUD methods. Usually empty.
```hcl
locals {
  locks = []  # Or ["virtualNetwork.vnet-name", "resourceGroup.rg-name"]
}
```

## Sensitive Fields

**⚠️ CRITICAL: Nested block sensitive fields MUST use independent ephemeral variables** (Terraform can't mix `ephemeral` with `optional()` in objects)

### Root-Level Sensitive
Modify variable in `variables.tf`: add `ephemeral = true`, remove `sensitive = true`. Create version var in `migrate_variables.tf`.

### Nested Block Sensitive (MANDATORY)
**ANY sensitive field inside nested block** (e.g., `os_profile.custom_data`, `*.admin_password`) requires:

1. **Independent ephemeral var** in `migrate_variables.tf`:
   ```hcl
   variable "migrate_{prefix}_{nested_path}_{field}" {
     type = string; nullable = <false if Required, true if Optional>; ephemeral = true
   }
   variable "migrate_{prefix}_{nested_path}_{field}_version" { type = number; default = 1 }
   ```

2. **Mark original field in `variables.tf`** (for code review):
   ```hcl
   variable "orchestrated_virtual_machine_scale_set_os_profile" {
     type = object({
       custom_data = optional(string)  # TODO: consider remove this - migrated to independent ephemeral variable (Task #97)
       # ...
     })
   }
   ```
   Add comment `# TODO: consider remove this - migrated to independent ephemeral variable (Task #X)` on the SAME LINE as the field definition.

3. **Use in locals** (`migrate_main.tf`):
   ```hcl
   sensitive_body = { properties = var.parent ? { path = { to = { field = var.migrate_var } } } : {} }
   sensitive_body_version = { "path.to.field" = var.migrate_var_version }
   ```

**Proof must show:** `Sensitive: true`, `Required/Optional`, independent var, version var, TODO comment added to variables.tf, usage in both locals.

## Task Types

### Type 1: Root-Level Argument
**Steps:** (1) Check `migrate_main.tf`, (2) Check `main.tf`, (3) **Query resource function for CustomizeDiff** (symbol=func, name=resource{Name}), (4) Query schema (entrypoint=schema), (5) **Check phase** (Create/Update), (6) Query Azure API, (7) **IMPLEMENT validations**, (8) **Check CustomizeDiff ForceNew**, (9) Add to local, (10) Create proof, (11) Update `track.md`, (12) **Self-review: Remove content not in scope**.
**Special - name (Task #1):** Create complete `azapi_header`. Get `type` from track.md. Do NOT add hidden fields like `kind` - those belong to `__check_root_hidden_fields__` task.
**Special - resource_group_name (Task #2):** Create `{prefix}_{parent_type}_id` in `migrate_variables.tf`, use in `parent_id`, NOT in body.

### Type 2: Check Root Hidden Fields
**Steps:** (1) Query Create with `query_terraform_block_implementation_source_code`, (2) **Check Two-Phase** (create method → update method), (3) Document phases, (4) Find hardcoded values NO schema, (5) **Check locks** (see below), (6) Add to `local.body.properties`, (7) Add to `local.locks`, (8) Create proof, (9) Update `track.md`.
**Two-Phase Pattern:** `client.CreateThenPoll(...)` → field assign → `client.UpdateThenPoll(...)`. Method names vary.

**Lock Detection (MANDATORY for Type 2):**
Search Create/Update/Delete methods for lock patterns:
- `locks.ByName(name, resourceType)` → Single lock
- `locks.MultipleByName(&names, resourceType)` → Multiple locks
- Extract lock construction logic (e.g., parsing subnet IDs to get VNet names)
- Build lock strings in format: `"{resourceType}.{dynamicOrStaticName}"`
- Add to `local.locks` list
- Document in proof with Go code evidence
```

### Type 3: Block Structure Skeleton
**Create skeleton ONLY:**
```hcl
locals {
  body = {
    properties = merge(
      var.os_disk != null ? {
        virtualMachineProfile = { storageProfile = { osDisk = { # caching = ... # Task #88
        } } }
      } : {}
    )
  }
}
```
**Steps:** (1) Check `main.tf`, (2) Create conditional skeleton with placeholders, (3) Check expand for hidden, (4) Create proof, (5) Update `track.md`.

### Type 4: Block Argument
**Prerequisites:** Parent skeleton exists (Type 3 done).
**Steps:** (1) Verify skeleton, (2) **Query resource function for CustomizeDiff**, (3) Query schema, (4) **Check phase**, (5) Query Azure API, (6) **IMPLEMENT validations**, (7) **Check CustomizeDiff ForceNew**, (8) **REPLACE comment placeholder**, (9-10) Handle sensitive/ForceNew, (11) Create proof, (12) Update track.md.

### Type 5: Post-Creation Update
**When:** Field in Update phase of Create method.
**Steps:** (1) Confirm Update phase, (2-4) Query schema/API, (5) **Check and IMPLEMENT validations** (MANDATORY), (6) Add to `local.post_creation_updates`, (7-8) Handle sensitive/proof, (9) Update `track.md`.

## Special Patterns

### Reading Existing State
Only if task needs Update logic or CustomizeDiff:
```hcl
data "azapi_resource" "existing" {
  type = "..."; name = var.name; parent_id = var.parent_id; ignore_not_found = true; response_export_values = ["*"]
}
locals {
  existing_value = data.azapi_resource.existing.exists ? try(data.azapi_resource.existing.output.path, default) : default
}
```

### Naming
snake_case → camelCase. Keep uppercase: `SSD`, `VM`, `OS`

## Proof Document Requirements
**File:** `{task_num}.{field}.md`
**Must Have:**
1. **Shadow Implementation** (code with `# <-` markers in proof ONLY)
2. **Summary** (1-2 sentences)
3. **Create Phase Verification (MANDATORY):** Query Create method, identify pattern (single/two-phase), classify field (Create/Update phase), document with Go code evidence, state decision.
4. **Assignment Path Verification (MANDATORY):** Predicted path → Go code evidence → Verified path (trace ALL assignments, especially `.Properties = &props`, `.Settings = &settings`) → Path comparison (match/mismatch)
5. **Provider Schema** (Go source - PRIMARY)
6. **Azure API Schema** (property path)
7. **Hidden Fields** (if any)
8. **Locks Detection** (Type 2 only - MANDATORY): Query all CRUD methods, identify lock patterns, show Go code evidence, construct lock strings
9. **Mapping** (snake_case → camelCase)
10. **Special Handling** (ForceNew/Sensitive/Validation/Post-Creation)
11. **Critical Review & Edge Case (MANDATORY):** Null semantics, boundary conditions, idempotency, safe references. Add "Edge Case Analysis" section.
12. **Checklist**

**Critical Review Questions:**
- Null meaning? ("Use default" vs "Keep existing" vs "Remove")
- Edge cases? (Empty collections, `""`, `0`, `false`, `null`)
- Idempotent? (No order-dependent, use `contains()` for arrays)
- Safe refs? (Check null before nested access)

⚠️ `# <-` markers ONLY in proof, NEVER in code files

**⚠️ CRITICAL: Proof Document Self-Check Before Writing**

Before writing ANY content to the proof document, you MUST perform this self-check:

**FORBIDDEN CONTENT - If found, FAIL the task immediately:**
- ❌ Phrases like "more conservative than provider"
- ❌ Phrases like "simpler approach"
- ❌ Phrases like "safer implementation"
- ❌ Phrases like "this is acceptable because..."
- ❌ Justifications for NOT following exact provider behavior
- ❌ Explanations about why exact replication is "difficult" or "complex"
- ❌ Rationales for trade-offs or compromises
- ❌ Statements like "close enough to provider behavior"
- ❌ Any text defending a deviation from exact provider logic

**If your proof document contains ANY of the above:**
1. STOP immediately
2. Delete the proof document
3. Mark task as Failed in track.md
4. Create error.md explaining why exact replication is impossible
5. Do NOT attempt to justify or rationalize approximate implementations

**The ONLY acceptable approaches:**
- ✅ "Implementation exactly matches provider behavior" with Go code evidence
- ✅ "Task FAILED because exact replication is technically impossible" (in error.md, not proof)

**This check must be performed BEFORE writing the proof document file.**

## Create Phase Verification (Detail)
1. Query Create: `query_terraform_block_implementation_source_code` with `entrypoint_name=create`
2. Identify: Single-phase (`CreateOrUpdate`) vs Two-phase (create method → field assign → update method)
3. Classify: Create phase (before create call) → `local.body` | Update phase (after create, before update) → `local.post_creation_updates`
4. Document in proof with Go evidence

## Assignment Path Verification (Detail)
Must trace ALL struct assignments in Go code, especially:
- `.Properties = &someProps` (adds nesting)
- `.Settings = &someSettings`
- Intermediate struct assignments
- Pointer assignments
Prevents wrong nesting bugs.

## Initial Templates (First Executor)

**migrate_main.tf:**
```hcl
locals {
  replace_triggers_external_values = {}
  body = { properties = {} }
  sensitive_body = { properties = {} }
  sensitive_body_version = {}
  azapi_header = {}  # type from track.md Task #1
  post_creation_updates = compact([])
  locks = []  # Populated by Type 2 task
}
```

**migrate_outputs.tf:**
```hcl
output "azapi_header" { value = local.azapi_header; depends_on = [] }
output "body" { value = local.body }
output "sensitive_body" { value = local.sensitive_body; sensitive = true; ephemeral = true }
output "sensitive_body_version" { value = local.sensitive_body_version }
output "replace_triggers_external_values" { value = local.replace_triggers_external_values }
output "post_creation_updates" { value = local.post_creation_updates; sensitive = true }
output "locks" { value = local.locks }
```

**migrate_validation.tf:** `# Complex runtime validations only. Most in variables.tf`
**migrate_variables.tf:** `# New variables only`

## Completion Checklist
- ✅ Property in correct local
- ✅ ForceNew wrapped: `{ value = var.field }`
- ✅ **ALL logic EXACTLY replicated from provider (no shortcuts, no "safer" alternatives)**
- ✅ **Validations IMPLEMENTED in variables.tf (MANDATORY - not deferred to Azure API)**
- ✅ **TODO comment added to original field in variables.tf (if sensitive field migrated to independent ephemeral variable)**
- ✅ Hidden fields checked
- ✅ Critical review (null, edge, idempotent, safe refs)
- ✅ Edge Case Analysis in proof
- ✅ Proof created
- ✅ `track.md` updated to Pending for check
- ✅ **Self-Review: Did I add ONLY what my task requires? Did I add things that belong to other tasks?**

## Three Prohibitions
1. ❌ NO CLI tools (`terraform`, `git`)
2. ❌ NO modifying `main.tf`. Only modify `variables.tf` when explicitly documented in instructions
3. ❌ NO copying examples - YOUR task only

## When to Fail a Task

**You MUST fail a task when exact replication of provider logic is technically impossible.**

**Common scenarios requiring failure:**
- Complex Go logic with no Terraform equivalent
- External API calls beyond simple state reading
- Runtime conditions that cannot be evaluated at plan time
- Provider behavior dependent on unavailable external state

**Error Document Format (error.md):**
```markdown
# Task #{number} - {field_name} - FAILED

## Reason for Failure
[Why exact replication is technically impossible]

## Provider Behavior
```go
[Quote exact Go code that cannot be replicated]
```

## Attempted Solutions
1. [What you tried]
2. [Why it didn't work]

## Recommendation
[Alternative approach or note that manual migration is required]
```

**Before failing:**
- ✅ Try using `data "azapi_resource"` blocks for state reading
- ✅ Try complex Terraform expressions
- ✅ Consult all available provider source code

**Never fail because:**
- ❌ Implementation is "hard" or "complex"
- ❌ You want to use a "simpler" approach
- ❌ You think a "more conservative" strategy is "safer"

## Common Mistakes
❌ Direct: `field = var.field` | ✅ Wrapped: `field = { value = var.field }`
❌ Wrong name: `replace_triggers` | ✅ Correct: `replace_triggers_external_values`
❌ Unwrapped conditional: `field = var.x ? var.y : null` | ✅ Wrapped: `field = { value = var.x ? var.y : null }`
❌ Unstable keys: `merge({}, cond ? {key: val} : {})` | ✅ Stable keys: `key = { value = cond ? val : "" }`
❌ "Let's use a more conservative approach for safety" | ✅ Replicate EXACT provider logic or FAIL
❌ "The logic is complex, so we'll simplify it" | ✅ Use data blocks and complex expressions to match exactly
❌ "This is close enough to the original behavior" | ✅ Must be IDENTICAL behavior or FAIL

## Final Context
Your locals feed root module's `azapi_resource`:
```hcl
resource "azapi_resource" "this" {
  type = local.azapi_header.type; name = local.azapi_header.name; location = local.azapi_header.location
  parent_id = local.azapi_header.parent_id; body = jsonencode(merge(local.body, local.sensitive_body))
  replace_triggers_external_values = local.replace_triggers_external_values
  dynamic "timeouts" { for_each = local.sensitive_body_version; content {} }
}
```

Build one field/block at a time. Keep modular.
