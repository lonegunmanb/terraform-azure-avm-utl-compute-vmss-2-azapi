# Common Terraform Error Patterns

This document collects common Terraform error patterns (and a few high-impact anti-patterns) along with practical fixes.

## Table of contents

- [1. Circular Variable Validation (Mutually Exclusive Deadlock)](#1-circular-variable-validation-mutually-exclusive-deadlock)
- [2. Inconsistent Conditional Result Types (Type Shape Mismatch)](#2-inconsistent-conditional-result-types-type-shape-mismatch)
- [3. Redundant Module Outputs (Duplicate Data Anti-pattern)](#3-redundant-module-outputs-duplicate-data-anti-pattern)
- [4. Retryable Errors Without Retry Configuration](#4-retryable-errors-without-retry-configuration)

---

## 1. Circular Variable Validation (Mutually Exclusive Deadlock)

### Intent

The developer intends to enforce a mutually exclusive relationship between two or more input variables ("if A is set, B must be null, and vice versa"). To be thorough, they add validation rules to *both* variables and each validation references the other variable.

### Problem

Terraform builds a dependency graph (DAG) to evaluate expressions.

* If `var.A`'s validation block references `var.B`, then `var.A` depends on `var.B`.
* If `var.B`'s validation block simultaneously references `var.A`, then `var.B` depends on `var.A`.

This creates a cycle (A → B → A). Terraform cannot determine an evaluation order, so planning/validation fails.

### Solution

Break the cycle by making the dependency **one-way**. Keep the business rule (mutual exclusion), but express it in only one place.

**Step-by-Step Fix:**

1. **Choose** which variable will be the "Validator" (downstream dependency)
2. **Remove** the cross-reference validation from the FIRST variable (upstream) - but ONLY the one that references the other variable
3. **Keep** any format/regex validations on the first variable
4. **Add** the mutual exclusivity validation to the SECOND variable (downstream)
5. **Verify** the chosen variable now has both its self-validation and the conflict check

**The Result:**
* Variable A: Only validates its own shape/format
* Variable B: Validates its own shape/format **and** checks the conflict against Variable A

Note: If your Terraform version/provider constraints prevent referencing other variables in `validation`, enforce mutual exclusion using a separate check (for example a precondition on a `terraform_data`/resource) rather than duplicating cross-references.

### Sample Code

**❌ Bad Code (The Cycle):**

Both variables reference each other. Terraform cannot resolve this.

```hcl
variable "capacity_reservation_group_id" {
  default = null
  # Dependent on proximity_placement_group_id
  validation {
    condition     = var.capacity_reservation_group_id == null || var.proximity_placement_group_id == null
    error_message = "Conflict!"
  }
}

variable "proximity_placement_group_id" {
  default = null
  # Dependent on capacity_reservation_group_id
  validation {
    condition     = var.proximity_placement_group_id == null || var.capacity_reservation_group_id == null
    error_message = "Conflict!"
  }
}
```

**✅ Good Code (One-way Fix):**

We put the conflict logic entirely into `proximity_placement_group_id`. `capacity_reservation_group_id` becomes independent, breaking the cycle.

The rule still exists; it is just defined in one place.

```hcl
variable "capacity_reservation_group_id" {
  type        = string
  default     = null
  description = "Specifies the ID of the Capacity Reservation Group."

  # FIX: Only validate the format of this variable; do not reference other variables here.
  validation {
    condition = (
      var.capacity_reservation_group_id == null ||
      can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Compute/capacityReservationGroups/[^/]+$", var.capacity_reservation_group_id))
    )
    error_message = "The capacity_reservation_group_id must be a valid ID."
  }
}

variable "proximity_placement_group_id" {
  type        = string
  default     = null
  description = "Specifies the ID of the Proximity Placement Group."

  # Validation 1: Check format of self
  validation {
    condition = (
      var.proximity_placement_group_id == null || 
      can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Compute/proximityPlacementGroups/[^/]+$", var.proximity_placement_group_id))
    )
    error_message = "The proximity_placement_group_id must be a valid ID."
  }

  # Validation 2: Check for conflicts (consolidated here). This creates a one-way dependency.
  validation {
    condition = (
      var.proximity_placement_group_id == null || 
      var.capacity_reservation_group_id == null
    )
    error_message = "Conflict: 'proximity_placement_group_id' cannot be set if 'capacity_reservation_group_id' is already used."
  }
}
```

---

## 2. Inconsistent Conditional Result Types (Type Shape Mismatch)

### Intent

The developer wants to build an object where some attributes are conditionally included. They use ternary conditionals (`condition ? {...} : {...}`), often nested, where each branch returns a different object “shape”.

### Problem

Terraform requires both branches of a conditional expression to have consistent types. For objects, that means the same attribute set at each level of the object. If one branch includes attribute `b` and the other does not, Terraform cannot unify the types.

**Common triggers:**

* `condition ? {a = 1, b = 2} : {a = 1}`
* Nested conditionals where inner objects differ per branch
* Returning `{}` in one branch and a non-empty object in the other

**Error message pattern:**
```
Error: Inconsistent conditional result types
The true and false result expressions must have consistent types.
The 'true' value includes object attribute "X", which is absent in the 'false' value.
```

### Solution

Make the object shape consistent, and only vary *values*. Two common techniques:

1. Use `merge()` to conditionally add attributes (each conditional returns either `{ attr = value }` or `{}`)
2. Alternatively, include the attribute in all branches and set it to `null` when “disabled” (when the downstream consumer accepts null)

**Key transformation pattern (via `merge()`):**

**❌ Before (inconsistent):**
```hcl
condition1 ? {
  properties = {a = 1, b = 2, c = 3}
} : condition2 ? {
  properties = {a = 1, c = 3}
} : {
  properties = {c = 3}
}
```

**✅ After (consistent):**
```hcl
{
  properties = merge(
    condition1 ? {a = 1} : {},
    condition1 ? {b = 2} : {},
    {c = 3}
  )
}
```

### Sample Code

**❌ Bad Code (nested conditionals with inconsistent structures):**

```hcl
locals {
  config = {
    name = "example"
    settings = var.enable_advanced ? {
      properties = merge(
        {
          basicSetting = "value1"
        },
        var.enable_dns ? {
          dnsSettings = {
            domain = var.domain_name
          }
        } : {},
        {
          timeout = 30
        }
      )
    } : var.enable_timeout ? {
      properties = merge(
        {
          timeout = 30
        },
        var.enable_prefix ? {
          prefix = var.prefix_id
        } : {}
      )
    } : {
      properties = {
        # Note: No basicSetting, no dnsSettings, no timeout here
        fallbackMode = true
      }
    }
  }
}
```

**✅ Good Code (single structure; conditionals only add attributes):**

```hcl
locals {
  config = {
    name = "example"
    settings = {
      properties = merge(
        var.enable_advanced ? {
          basicSetting = "value1"
        } : {},
        var.enable_dns && var.enable_advanced ? {
          dnsSettings = {
            domain = var.domain_name
          }
        } : {},
        var.enable_timeout || var.enable_advanced ? {
          timeout = 30
        } : {},
        var.enable_prefix && !var.enable_advanced ? {
          prefix = var.prefix_id
        } : {},
        !var.enable_advanced && !var.enable_timeout ? {
          fallbackMode = true
        } : {}
      )
    }
  }
}
```

---

---
## 3. Redundant Module Outputs (Duplicate Data Anti-pattern)

### Intent

The developer wants to expose a value from a module (e.g., `tags`) so that consuming code can reference it. To make the module easier to use, they create a dedicated output for this value. However, the same value is already included as an attribute within another composite output (e.g., as part of a `header` or `config` object).

### Problem

Redundant outputs aren’t always a Terraform core error by themselves, but they commonly lead to confusion and downstream failures (especially during refactors) because consumers pick inconsistent output paths.

Redundant outputs:

1. **Duplicate data**: The same value is exposed through multiple output paths
2. **Increase maintenance burden**: Changes to the value must be synchronized across multiple outputs
3. **Cause confusion**: Consumers don't know which output to use (`module.example.tags` vs `module.example.header.tags`)
4. **Add unnecessary complexity**: Extra outputs clutter the module interface

**Common error patterns in consuming code:**
- `Error: Unsupported attribute` - when trying to reference an output that doesn't exist
- `This object does not have an attribute named "X"` - when the attribute exists elsewhere in the module outputs

**Common scenarios:**
- Value is already part of a composite object (e.g., `header`, `config`, `metadata`)
- Module refactoring moved the value into a different output structure
- Copy-paste from examples that used an older module version

### Solution

Expose each piece of data through one canonical output path. If it’s already available in a composite object, reference it from there rather than creating a duplicate top-level output.

**Step-by-Step Fix:**

1. **Identify** where the value is actually defined in the module
2. **Check** if the value is already included in another output (e.g., as part of a composite object)
3. **If redundant output exists**: Remove it (or keep it temporarily as an explicitly documented alias if you need backwards compatibility)
4. **Update consuming code**: Change references to use the canonical path (e.g., `module.example.header.attribute`)
5. **Verify**: Ensure no other code depends on the redundant output path

**Key Decision Tree:**
```
Is value already in a composite output (header/config/etc)?
├─ YES → Remove redundant output, use composite path
└─ NO → Keep/add dedicated output for the value
```

### Sample Code

**❌ Bad Code (Redundant Outputs):**

**Module outputs.tf:**
```hcl
locals {
  header = {
    type      = var.resource_type
    name      = var.name
    location  = var.location
    parent_id = var.parent_id
    tags      = var.tags  # tags is here
  }
}

output "header" {
  value = local.header
}

# REDUNDANT: tags is already in header
output "tags" {
  value = var.tags  # Duplicate!
}

output "body" {
  value = local.body
}
```

**Consuming code:**
```hcl
resource "azapi_resource" "example" {
  type      = module.config.header.type
  name      = module.config.header.name
  location  = module.config.header.location
  parent_id = module.config.header.parent_id
  tags      = module.config.tags  # Using separate output
  body      = module.config.body
}
```

**Problem**: 
- `tags` appears in **two places**: `module.config.header.tags` and `module.config.tags`
- If the module changes how tags are computed, both outputs must be updated
- Consumers might use either path inconsistently

**✅ Good Code (Single Canonical Path):**

**Module outputs.tf:**
```hcl
locals {
  header = {
    type      = var.resource_type
    name      = var.name
    location  = var.location
    parent_id = var.parent_id
    tags      = var.tags
  }
}

output "header" {
  value = local.header
}

# REMOVED: Redundant tags output deleted

output "body" {
  value = local.body
}
```

**Consuming code:**
```hcl
resource "azapi_resource" "example" {
  type      = module.config.header.type
  name      = module.config.header.name
  location  = module.config.header.location
  parent_id = module.config.header.parent_id
  tags      = module.config.header.tags  # Using canonical path from header
  body      = module.config.body
}
```

**What Changed:**
- **Removed** the redundant `output "tags"` from the module
- **Updated** consuming code to reference `module.config.header.tags` instead of `module.config.tags`
- **Result**: Single source of truth, cleaner module interface

**Another Example - Metadata in Config Object:**

**❌ Bad Code:**
```hcl
# Module outputs
output "config" {
  value = {
    settings = local.settings
    metadata = {
      version     = local.version
      environment = var.environment
      region      = var.region
    }
  }
}

# Redundant outputs
output "version" {
  value = local.version
}

output "environment" {
  value = var.environment
}

output "region" {
  value = var.region
}
```

**✅ Good Code:**
```hcl
# Module outputs
output "config" {
  value = {
    settings = local.settings
    metadata = {
      version     = local.version
      environment = var.environment
      region      = var.region
    }
  }
}

# No redundant outputs - use module.example.config.metadata.version, etc.
```

**When Duplicate Outputs ARE Acceptable:**

Sometimes duplication is intentional for **convenience or backwards compatibility**:

```hcl
output "full_config" {
  description = "Complete configuration object with all nested data"
  value       = local.full_config
}

output "id" {
  description = "Convenience output for resource ID (also in full_config.id)"
  value       = local.full_config.id
}
```

This can be acceptable when:
- The convenience output is **well-documented** as an alias
- It provides significant **ergonomic benefit** (e.g., `module.example.id` vs `module.example.full_config.metadata.resource.id`)
- It's for **backwards compatibility** during a migration period

---

## 4. Retryable Errors Without Retry Configuration

### Intent

The developer expects Terraform operations to succeed reliably, but occasionally encounters transient errors from cloud providers (rate limiting, resource unavailability, throttling) that would succeed if retried.

### Problem

Azure and other cloud providers return transient errors that are retryable. Without proper retry configuration, Terraform operations fail immediately, requiring manual re-execution.

**Common retryable error indicators:**
- Error messages containing "retryable", "try later", "try again later", "please retry"
- HTTP 429 (Too Many Requests) / rate limiting errors
- Temporary backend unavailability / resource busy errors

### Solution

When you encounter a retryable error, add the error message pattern to the replicator module's `local.retry.error_message_regex` list. Terraform will then automatically retry failed operations.

**Step-by-Step Fix:**

1. **Identify** the retryable error message in Terraform output
2. **Extract** the key pattern (distinctive text identifying the error type)
3. **Add** the pattern to `local.retry.error_message_regex` list in the replicator module

### Sample Code

**❌ Bad Code:**

```hcl
locals {
  retry = {
    error_message_regex = [
      # Empty - missing retryable patterns
    ]
  }
}
```

**✅ Good Code:**

```hcl
locals {
  retry = {
    error_message_regex = [
      "retryable",
      "try later",
      "try again later",
      "please retry",
      "429 Too Many Requests",
      "rate limit",
      "temporarily unavailable",
      "resource busy",
      "throttling",
      "TooManyRequests",
    ]
  }
}
```

**Real Example:**

Error seen:
```
Error: compute.VirtualMachineScaleSetsClient#CreateOrUpdate: 
retryable error: received 429 status code
```

Pattern added:
```hcl
error_message_regex = [
  "retryable",           # Catches "retryable error"
  "429.*status.*code",   # Catches "429 status code"
]
```

**Best Practices:**
- Start with common patterns, add more as you encounter them
- Use simple substring matching when possible
- Balance specificity (avoid false positives) with generality (catch variations)

**Do NOT add retry patterns for permanent failures** (auth errors, quota exhausted, invalid config, validation failures) - these require code changes, not retries.

---