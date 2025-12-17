# Acceptable Drift Patterns for AzureRM to AzAPI Migration

This document defines acceptable drift patterns when migrating from AzureRM provider resources to AzAPI provider resources using moved blocks. These patterns apply to all resource types during state migration.

## ⚠️ CRITICAL: Whitelist Approach

**This document uses a WHITELIST approach**: 

- ✅ **ONLY** the drift patterns explicitly listed below as "acceptable" are considered acceptable
- ❌ **ANY** drift pattern NOT explicitly listed in this document is considered UNACCEPTABLE and indicates a module implementation error
- When evaluating test results, if a drift doesn't match any pattern described in sections 1-3 below, it must be treated as a failure

## Acceptable Drift Patterns

### 1. AzAPI Resource-Level Attribute Changes

**⚠️ IMPORTANT**: ANY changes to these attributes are acceptable, regardless of from/to values.

✅ **Always acceptable attributes**:
- `ignore_null_property` - AzAPI behavior setting
- `locks` - Resource lock configuration
- `replace_triggers_external_values` - Module replacement tracking
- `sensitive_body_version` - Sensitive data versioning
- `output` - Computed output values
- `type` - API version changes (e.g., `@2025-04-01` → `@2024-11-01`)

**Rationale**: These are AzAPI provider implementation details that don't affect resource functionality. API version changes are expected as AzureRM and AzAPI may use different API versions for the same resource type.

### 2. Body Structure - Removed Default Values (Azure API Response Fields)

**Rule**: When you see a change in the `body` attribute, check the corresponding field's schema in the AzureRM provider:

✅ **Change is ACCEPTABLE if**:
- The field does NOT exist in AzureRM provider schema, OR
- The field exists with `Optional: true` AND `Computed: true`

❌ **Change is NOT ACCEPTABLE if**:
- The field exists in AzureRM provider but doesn't match the above criteria

**Why this happens**: Azure API returns many fields that AzureRM marks as "Optional + Computed" (meaning Azure provides defaults if you don't specify them). When migrating to AzAPI with `ignore_null_property = true`, these computed default values are removed from the plan.


## ❌ Everything Else is UNACCEPTABLE

**Any drift pattern not matching sections 1-3 above indicates a module implementation error.**

Common examples of unacceptable drifts (non-exhaustive list):

1. **Explicitly Configured Values Differ**: Values that were explicitly set in configuration show different values in the plan
2. **Missing Required Fields**: Required fields are not populated correctly
3. **Resource Recreation**: Plan shows destroy/create instead of update/in-place change
4. **Wrong Resource Type**: Fundamental resource type mismatch
5. **Data Loss Risk**: Changes that would cause data loss or service interruption
6. **Unexpected Property Changes**: Any property change in `body` that doesn't match Pattern #2 criteria
