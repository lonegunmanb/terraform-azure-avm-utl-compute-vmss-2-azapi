# DiffSuppressFunc Handling

**When to use this guide:** Apply these instructions whenever a provider schema attribute is defined with `DiffSuppressFunc`. The goal is to reproduce the provider’s suppression logic directly within Terraform locals so that expected updates are made and suppressed diffs remain hidden from Terraform plans.

## What is DiffSuppressFunc?

`DiffSuppressFunc` is a Go callback used by Terraform providers to decide whether a change in configuration should be ignored. Even if the desired configuration value differs from the current value, the callback can return `true` to signal “no diff,” preventing Terraform from proposing an update.

**Provider snippet example:**
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

## Implementation Strategy

For every field guarded by `DiffSuppressFunc`, recreate the suppression logic in Terraform and decide which value should be written into the outgoing request body. When the logic says to suppress a diff, insert the value currently stored by the remote resource; otherwise, insert the newly computed value.

### Step-by-Step Flow

1. **Derive the desired value.** Apply defaults, conversions, and validation exactly as the schema requires to obtain the fresh value you want to send.
2. **Gather existing state if needed.** When the suppression logic depends on the current value, read it via `data.azapi_resource.existing` (reuse existing patterns for optional state lookups).
3. **Mirror the Go conditions.** Compute a boolean `*_should_suppress` that matches the provider’s DiffSuppress function precisely.
4. **Select the effective value.** If suppression is required, reuse the existing value (falling back to the new value when the existing state is unavailable). If suppression is not required, keep the new value.
5. **Populate the request body.** Assign the effective value under the correct body path. No auxiliary triggers or version counters are needed—everything flows through the standard body payload.

### Value Selection Template

```hcl
locals {
  should_read_existing_field = (
    # Determine whether the DiffSuppress logic requires the current value
  )

  existing_field_value = local.should_read_existing_field && data.azapi_resource.existing.exists
    ? try(data.azapi_resource.existing.output.properties.path.to.field, null)
    : null

  desired_field_value = local.computed_field_value

  field_should_suppress = (
    # Replicate DiffSuppressFunc conditions here
  )

  effective_field_value = local.field_should_suppress
    ? coalesce(local.existing_field_value, local.desired_field_value)
    : local.desired_field_value
}
```

### Request Body Template

```hcl
locals {
  body = {
    properties = {
      path = {
        to = {
          field = local.effective_field_value
        }
      }
    }
  }
}
```

**Key reminders:**

- The suppression logic lives entirely in Terraform locals.
- Suppression is achieved by reusing the existing value when the provider would consider the diff ignorable.
- Always fall back to the desired value if the existing value is `null` or unavailable.
- Guard reads from `data.azapi_resource.existing` with its `exists` flag (optionally gated by your own boolean) so the template works even when no existing resource is present.
- This pattern relies solely on the standard request body—no external triggers or secondary resources are involved.

## Proof Requirements

When documenting compliance with this pattern, include:

1. **Exact DiffSuppressFunc source.** Paste the Go implementation from the provider.
2. **Terraform translation.** Show the locals that replicate the suppression logic.
3. **State handling.** Demonstrate how the existing value is obtained, or justify when it is unnecessary.
4. **Effective value selection.** Provide the local that chooses between existing and desired values.
5. **Body snippet.** Show the portion of the body map that receives the effective value.
6. **Behavior review.** Explain how suppression and non-suppression scenarios play out and include test evidence for both cases.

## Common Mistakes

❌ Skipping the state lookup even though the suppression logic requires the current value.

❌ Forgetting to recreate the provider’s boolean logic exactly, leading to unwanted updates or missed suppressions.

❌ Overwriting the resource with a `null` value when the existing state is absent (always fall back to the desired value).

❌ Hard-coding the existing value without conditionally switching back to the new value when suppression should not happen.

✅ Correct implementations compute the boolean flag, derive the effective value, and inject that value directly into the body map.

## Summary Checklist

- ✅ Quote the provider’s `DiffSuppressFunc` in your proof document.
- ✅ Compute the desired configuration value with all required defaults.
- ✅ Read existing state whenever the suppression logic references previous values.
- ✅ Reproduce the suppression condition exactly as written in Go.
- ✅ Choose between existing and desired values before writing to the body.
- ✅ Present the body map that carries the effective value.
- ✅ Document both suppress and non-suppress scenarios with expected body contents.
