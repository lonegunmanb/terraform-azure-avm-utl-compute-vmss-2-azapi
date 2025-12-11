# Deferred Work Tracking

This file tracks work that has been deferred from one task to another task that owns the referenced field.

| Deferred By | Deferred To | Type | Description | Status |
|-------------|-------------|------|-------------|--------|
| #74 | #76 | Validation | Cross-field validation: When primary is true, version cannot be IPv6. Error message: "an IPv6 Primary IP Configuration is unsupported - instead add a IPv4 IP Configuration as the Primary and make the IPv6 IP Configuration the secondary" | ✅ Completed |
| #118 | Multiple (#120, #121, #18, #152-156, #43-56) | Validation | Complex hotpatching validations requiring image reference parsing and cross-field checks. (1) When using hotpatch-enabled images: patch_mode must be AutomaticByPlatform, provision_vm_agent must be true, health extension required, hotpatching_enabled must be true. (2) When NOT using hotpatch-enabled images: hotpatching_enabled must be false. Implementation requires isValidHotPatchSourceImageReference() logic. | Pending |
