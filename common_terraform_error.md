# Common Terraform Error Patterns

This document records common incorrect patterns in Terraform and their solutions.

---

## 1. Circular Variable Validation (The Mutually Exclusive Deadlock)

### Intent

The developer intends to enforce a **"Mutually Exclusive" (ConflictsWith)** relationship between two or more input variables. The goal is to ensure that if Variable A is set, Variable B must be null, and vice versa. To be thorough, the developer adds a validation rule to **both** variables, referencing each other to catch the error regardless of which one is modified.

### Problem

Terraform builds a dependency graph (DAG) to evaluate variables and resources.

* If `var.A`'s validation block references `var.B`, then `var.A` depends on `var.B`.
* If `var.B`'s validation block simultaneously references `var.A`, then `var.B` depends on `var.A`.

This creates a **Cycle (A -> B -> A)**, causing the Terraform core to crash or error out during the graph walk, because it cannot determine which variable to evaluate first.

### Solution

You must **break the cycle** by making the dependency "uni-directional."

⚠️ **CRITICAL: MOVE validation, DO NOT REMOVE it!**

The mutual exclusivity validation logic MUST be preserved. You are **MOVING** it from one variable to another, **NOT DELETING** it. The validation ensures both variables cannot be set simultaneously - this business logic must remain intact.

**Step-by-Step Fix:**

1. **Choose** which variable will be the "Validator" (downstream dependency)
2. **Remove** the cross-reference validation from the FIRST variable (upstream) - but ONLY the one that references the other variable
3. **Keep** any format/regex validations on the first variable
4. **Add** the mutual exclusivity validation to the SECOND variable (downstream)
5. **Verify** the second variable now has BOTH its format validation AND the conflict check

**The Result:**
* First variable (Upstream): Only validates its own format (e.g., regex)
* Second variable (Downstream): Validates its own format **AND** checks for the conflict against the first variable
* *Note: This feature (referencing other variables in validation) requires Terraform v1.9+.*

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

**✅ Good Code (The Uni-directional Fix):**

We **MOVE** the conflict logic entirely into `proximity_placement_group_id`. `capacity_reservation_group_id` becomes a pure independent variable, breaking the cycle.

**⚠️ Notice: The validation is MOVED, not removed!**
- The validation from `capacity_reservation_group_id` that referenced `proximity_placement_group_id` is **removed** from the first variable
- The SAME validation logic is **added** to `proximity_placement_group_id` 
- The net result: Same validation exists, but in only ONE place

```hcl
variable "capacity_reservation_group_id" {
  type        = string
  default     = null
  description = "Specifies the ID of the Capacity Reservation Group."

  # FIX: Only validate the format of THIS variable. Do not reference other variables here.
  # The mutual exclusivity validation was MOVED to proximity_placement_group_id below.
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

  # Validation 2: MOVED HERE - Check for conflicts (The logic is consolidated here)
  # This creates a dependency: proximity -> capacity. There is no return loop.
  # ⚠️ This validation was MOVED from capacity_reservation_group_id to here.
  validation {
    condition = (
      var.proximity_placement_group_id == null || 
      var.capacity_reservation_group_id == null
    )
    error_message = "Conflict: 'proximity_placement_group_id' cannot be set if 'capacity_reservation_group_id' is already used."
  }
}
```

**Validation Count Verification:**
- **Before fix**: `capacity_reservation_group_id` has 1 format validation + 1 conflict validation = 2 validations; `proximity_placement_group_id` has 1 format validation + 1 conflict validation = 2 validations. **Total: 4 validations**
- **After fix**: `capacity_reservation_group_id` has 1 format validation = 1 validation; `proximity_placement_group_id` has 1 format validation + 1 conflict validation = 2 validations. **Total: 3 validations**
- **Net change**: Removed 1 duplicate conflict validation. The business logic is preserved - both variables still cannot be set simultaneously.

---
